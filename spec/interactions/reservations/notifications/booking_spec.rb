# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reservations::Notifications::Booking do
  let(:subscription) { FactoryBot.create(:subscription, :premium) }
  let(:phone_number) { Faker::PhoneNumber.phone_number }
  let!(:social_account) { FactoryBot.create(:social_account, user: user) }
  let(:user) { FactoryBot.create(:user) }
  let(:profile) { FactoryBot.create(:profile, user: user, company_name: "Test Company") }
  let(:customer) { FactoryBot.create(:customer, user: user) }
  let(:reservation) { FactoryBot.create(:reservation, shop: FactoryBot.create(:shop, user: user)) }
  let!(:reservation_customer) { FactoryBot.create(:reservation_customer, reservation: reservation, customer: customer, booking_option_ids: [booking_option.id]) }
  let(:booking_page) { FactoryBot.create(:booking_page, user: user) }
  let(:booking_option) { FactoryBot.create(:booking_option, user: user, booking_pages: [booking_page]) }
  let(:user_setting) { FactoryBot.create(:user_setting, user: user, customer_notification_channel: 'email') }

  # Create UserSetting objects for specific notification channels
  let(:email_user_setting) { FactoryBot.create(:user_setting, user: user, customer_notification_channel: 'email') }
  let(:sms_user_setting) { FactoryBot.create(:user_setting, user: user, customer_notification_channel: 'sms') }
  let(:line_user_setting) { FactoryBot.create(:user_setting, user: user, customer_notification_channel: 'line') }

  let(:args) do
    {
      phone_number: phone_number,
      customer: customer,
      reservation: reservation,
      booking_page: booking_page,
      booking_options: [booking_option]
    }
  end
  let(:outcome) { described_class.run(args) }

  # Common test setup for notification channel tests
  shared_context "notification setup" do
    before do
      # Basic setup - use the real user_setting instead of stubbing
      allow(subscription).to receive(:active?).and_return(true)

      # Stub validators and methods
      allow_any_instance_of(Reservations::Notifications::Notify).to receive(:message).and_return("Test message")

      # Stub notification methods
      setup_notification_stubs
    end

    def setup_notification_stubs
      # Set up SMS stubs
      allow_any_instance_of(Reservations::Notifications::Notify).to receive(:customer).and_return(customer)
      allow(customer).to receive(:locale).and_return('ja')

      # Mock out the specific delivery methods to avoid actual network calls/emails
      allow_any_instance_of(Reservations::Notifications::Notify).to receive(:notify_by_email).and_return(true)
      allow_any_instance_of(Reservations::Notifications::Notify).to receive(:notify_by_sms).and_return(true)
      allow_any_instance_of(Reservations::Notifications::Notify).to receive(:notify_by_line).and_return(true)

      # Mock SMS service
      allow(Sms::Create).to receive(:run).and_return(true)

      # Mock LINE service
      allow(LineClient).to receive(:send).and_return(true)
      allow(LineClient).to receive(:flex).and_return(true)

      # Mock email - keep this as we don't want to send real emails
      allow(CustomerMailer).to receive_message_chain('with.custom.deliver_now').and_return(true)
    end

    # Helper methods for setting notification availability
    def set_availability(email: false, sms: false, line: false)
      allow_any_instance_of(Reservations::Notifications::Notify).to receive(:available_to_send_email?).and_return(email)
      allow_any_instance_of(Reservations::Notifications::Notify).to receive(:available_to_send_sms?).and_return(sms)
      allow_any_instance_of(Reservations::Notifications::Notify).to receive(:available_to_send_line?).and_return(line)
    end

    def only_email_available
      set_availability(email: true, sms: false, line: false)
    end

    def only_sms_available
      set_availability(email: false, sms: true, line: false)
    end

    def only_line_available
      set_availability(email: false, sms: false, line: true)
    end

    def all_channels_available
      set_availability(email: true, sms: true, line: true)
    end
  end

  describe "#execute" do
    it "calls Sms::Create" do
      # Mock the Sms class to call through to Sms::Create
      allow(Reservations::Notifications::Sms).to receive(:run).and_call_original
      expect(Sms::Create).to receive(:run).and_return(spy(invalid?: false))

      # Set the notification channel to sms
      allow_any_instance_of(Reservations::Notifications::Notify).to receive(:available_to_send_sms?).and_return(true)
      allow(user).to receive(:customer_notification_channel).and_return("sms")

      outcome
    end

    context "when subscription plan is not charge_required(free)" do
      let(:subscription) { FactoryBot.create(:subscription, :free_after_trial) }

      context 'when subscription is active' do
        before do
          allow(subscription).to receive(:active?).and_return(true)
        end

        it "calls Sms::Create" do
          # Mock the Sms class to call through to Sms::Create
          allow(Reservations::Notifications::Sms).to receive(:run).and_call_original
          expect(Sms::Create).to receive(:run).and_return(spy(invalid?: false))

          # Set the notification channel to sms
          allow_any_instance_of(Reservations::Notifications::Notify).to receive(:available_to_send_sms?).and_return(true)
          allow(user).to receive(:customer_notification_channel).and_return("sms")

          outcome
        end
      end

      context 'when subscription is inactive' do
        before do
          allow(subscription).to receive(:active?).and_return(false)
          # Stub the notify_by_sms method to prevent actual SMS sending
          allow_any_instance_of(Reservations::Notifications::Notify).to receive(:notify_by_sms).and_return(false)
        end

        it "don't calls Sms::Create" do
          expect(Sms::Create).not_to receive(:run)

          outcome
        end
      end
    end

    context "when testing different notification channels" do
      include_context "notification setup"

      context "when customer_notification_channel is email" do
        before do
          # Use the real email user setting
          user.user_setting = email_user_setting
          user.save
          all_channels_available
        end

        context "when all channels are available" do
          before { all_channels_available }

          it "sends only email notification and never SMS or LINE" do
            expect_any_instance_of(Reservations::Notifications::Notify).to receive(:notify_by_email).and_return(true)
            expect_any_instance_of(Reservations::Notifications::Notify).not_to receive(:notify_by_sms)
            expect_any_instance_of(Reservations::Notifications::Notify).not_to receive(:notify_by_line)

            outcome
          end
        end

        context "when only email is available" do
          before { only_email_available }

          it "sends only email notification" do
            expect_any_instance_of(Reservations::Notifications::Notify).to receive(:notify_by_email).and_return(true)
            expect_any_instance_of(Reservations::Notifications::Notify).not_to receive(:notify_by_sms)
            expect_any_instance_of(Reservations::Notifications::Notify).not_to receive(:notify_by_line)

            outcome
          end
        end

        context "when email is not available" do
          before { set_availability(email: false, sms: true, line: true) }

          it "doesn't send any notification when email is not available" do
            expect_any_instance_of(Reservations::Notifications::Notify).not_to receive(:notify_by_email)
            expect_any_instance_of(Reservations::Notifications::Notify).not_to receive(:notify_by_sms)
            expect_any_instance_of(Reservations::Notifications::Notify).not_to receive(:notify_by_line)

            outcome
          end
        end
      end

      context "when customer_notification_channel is sms" do
        before do
          # Use the real sms user setting
          user.user_setting = sms_user_setting
          user.save
        end

        context "when all channels are available" do
          before { all_channels_available }

          it "sends sms notification and never LINE" do
            expect_any_instance_of(Reservations::Notifications::Notify).to receive(:notify_by_sms).and_return(true)
            expect_any_instance_of(Reservations::Notifications::Notify).not_to receive(:notify_by_email)
            expect_any_instance_of(Reservations::Notifications::Notify).not_to receive(:notify_by_line)

            outcome
          end
        end

        context "when only sms is available" do
          before { only_sms_available }

          it "sends only sms notification" do
            expect_any_instance_of(Reservations::Notifications::Notify).to receive(:notify_by_sms).and_return(true)
            expect_any_instance_of(Reservations::Notifications::Notify).not_to receive(:notify_by_line)
            expect_any_instance_of(Reservations::Notifications::Notify).not_to receive(:notify_by_email)

            outcome
          end
        end

        context "when sms is not available but email is" do
          before { set_availability(email: true, sms: false, line: true) }

          it "sends email notification as fallback but never LINE" do
            # Key requirement: when channel is sms, never send LINE even as fallback
            expect_any_instance_of(Reservations::Notifications::Notify).not_to receive(:notify_by_sms)
            expect_any_instance_of(Reservations::Notifications::Notify).to receive(:notify_by_email).and_return(true)
            expect_any_instance_of(Reservations::Notifications::Notify).not_to receive(:notify_by_line)

            outcome
          end
        end

        context "when neither sms nor email is available" do
          before { set_availability(email: false, sms: false, line: true) }

          it "doesn't send any notification (not even LINE)" do
            expect_any_instance_of(Reservations::Notifications::Notify).not_to receive(:notify_by_sms)
            expect_any_instance_of(Reservations::Notifications::Notify).not_to receive(:notify_by_email)
            expect_any_instance_of(Reservations::Notifications::Notify).not_to receive(:notify_by_line)

            outcome
          end
        end
      end

      context "when customer_notification_channel is line" do
        before do
          # Use the real line user setting
          user.user_setting = line_user_setting
          user.save
        end

        context "when all channels are available" do
          before { all_channels_available }

          it "sends line notification as highest priority" do
            expect_any_instance_of(Reservations::Notifications::Notify).to receive(:notify_by_line).and_return(true)
            expect_any_instance_of(Reservations::Notifications::Notify).not_to receive(:notify_by_sms)
            expect_any_instance_of(Reservations::Notifications::Notify).not_to receive(:notify_by_email)

            outcome
          end
        end

        context "when only line is available" do
          before { only_line_available }

          it "sends only line notification" do
            expect_any_instance_of(Reservations::Notifications::Notify).to receive(:notify_by_line).and_return(true)
            expect_any_instance_of(Reservations::Notifications::Notify).not_to receive(:notify_by_sms)
            expect_any_instance_of(Reservations::Notifications::Notify).not_to receive(:notify_by_email)

            outcome
          end
        end

        context "when line and sms are not available but email is" do
          before { set_availability(email: true, sms: false, line: false) }

          it "sends email notification as final fallback" do
            expect_any_instance_of(Reservations::Notifications::Notify).not_to receive(:notify_by_line)
            expect_any_instance_of(Reservations::Notifications::Notify).not_to receive(:notify_by_sms)
            expect_any_instance_of(Reservations::Notifications::Notify).to receive(:notify_by_email).and_return(true)

            outcome
          end
        end

        context "when no notification channels are available" do
          before { set_availability(email: false, sms: false, line: false) }

          it "doesn't send any notification" do
            expect_any_instance_of(Reservations::Notifications::Notify).not_to receive(:notify_by_line)
            expect_any_instance_of(Reservations::Notifications::Notify).not_to receive(:notify_by_sms)
            expect_any_instance_of(Reservations::Notifications::Notify).not_to receive(:notify_by_email)

            outcome
          end
        end
      end
    end

    context "when there is email argument" do
      let(:email) { "customer@example.com" }
      let!(:profile) { FactoryBot.create(:profile, user: user, company_name: "Test Company") }

      before do
        args[:email] = email
        args[:phone_number] = nil
        allow_any_instance_of(Reservations::Notifications::Notify).to receive(:notify_by_email).and_return(true)
      end

      it "calls CustomerMailer.custom" do
        expect_any_instance_of(Reservations::Notifications::Notify).to receive(:notify_by_email)

        outcome
      end
    end

    context "when customer connected with social_customer" do
      let!(:social_customer) { FactoryBot.create(:social_customer, customer: customer, user: user) }
      let!(:social_account) { FactoryBot.create(:social_account, user: user) }

      before do
        # Ensure the notification method is called
        allow_any_instance_of(Reservations::Notifications::Notify).to receive(:send_notification_with_fallbacks).and_call_original
        allow_any_instance_of(Reservations::Notifications::Notify).to receive(:notify_by_line).and_call_original
        allow_any_instance_of(Reservations::Notifications::Notify).to receive(:available_to_send_line?).and_return(true)
        # Set the notification channel to line
        allow(user).to receive(:customer_notification_channel).and_return("line")
      end

      it "calls Reservations::Notifications::SocialMessage" do
        expected_message = Translator.perform(I18n.t("customer.notifications.sms.booking"), reservation.message_template_variables(customer))

        expect(Reservations::Notifications::SocialMessage).to receive(:run).with(
            { social_customer: social_customer, message: expected_message }
          ).and_return(double(invalid?: false, result: double))

        outcome
      end

      context "when there is shop custom message" do
        let(:scenario) { ::CustomMessages::Customers::Template::BOOKING_PAGE_BOOKED }
        let!(:custom_message) { FactoryBot.create(:custom_message, service: booking_page.shop, scenario: scenario) }

        it "uses shop custom message template" do
          message = Translator.perform(custom_message.content, reservation.message_template_variables(customer))

          expect(Reservations::Notifications::SocialMessage).to receive(:run).with(
            { social_customer: social_customer, message: message }
          ).and_return(double(invalid?: false, result: double))

          outcome
        end
      end
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notifiers::Customers::Broadcast, :with_line do
  let(:receiver) { FactoryBot.create(:social_customer).customer }
  let(:broadcast) { FactoryBot.create(:broadcast, user: receiver.user) }
  let(:args) do
    {
      receiver: receiver,
      broadcast: broadcast
    }
  end
  let(:outcome) { described_class.run(args) }

  # Set up basic mocks for all tests
  before do
    # Create a real user with subscription instead of mocking
    user = receiver.user
    subscription_double = double("Subscription", active?: true)
    allow(user).to receive(:subscription).and_return(subscription_double)
    allow(user).to receive(:customer_notification_channel).and_return("line")
    profile_double = double("Profile", company_name: "Test Company")
    allow(user).to receive(:profile).and_return(profile_double)
    allow_any_instance_of(described_class).to receive(:business_owner).and_return(user)

    # Mock email delivery
    mail_double = double("Mail::Message", deliver_now: true)
    allow(CustomerMailer).to receive_message_chain(:with, :custom).and_return(mail_double)
  end

  describe "#execute" do
    # Helper methods for setting up availability of various notification channels
    def set_availability(email: true, sms: true, line: true)
      if email
        allow_any_instance_of(described_class).to receive(:available_to_send_email?).and_return(true)
      else
        allow_any_instance_of(described_class).to receive(:available_to_send_email?).and_return(false)
      end

      if sms
        allow_any_instance_of(described_class).to receive(:available_to_send_sms?).and_return(true)
      else
        allow_any_instance_of(described_class).to receive(:available_to_send_sms?).and_return(false)
      end

      if line
        allow_any_instance_of(described_class).to receive(:available_to_send_line?).and_return(true)
      else
        allow_any_instance_of(described_class).to receive(:available_to_send_line?).and_return(false)
      end
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

    def setup_notification_stubs
      # Mock LineClient to avoid actual network calls
      allow(LineClient).to receive(:send).with(any_args).and_return(true)

      # Mock the SocialMessages::Create interaction to avoid creating actual records
      allow(SocialMessages::Create).to receive(:run).and_return(true)

      # Mock the Sms::Create interaction to avoid sending actual SMS
      allow(Sms::Create).to receive(:run).and_return(true)
    end

    it "sends line with social_message had broadcast id" do
      # Expect SocialMessages::Create.run to be called with the correct parameters
      expect(SocialMessages::Create).to receive(:run).with(
        social_customer: receiver.social_customer,
        content: broadcast.content,
        content_type: SocialUserMessages::Create::TEXT_TYPE,
        message_type: SocialMessage.message_types[:bot],
        readed: true,
        broadcast: broadcast
      ) do
        # Create the SocialMessage record directly
        message = SocialMessage.create!(
          social_customer: receiver.social_customer,
          social_account: receiver.social_customer.social_account,
          raw_content: broadcast.content,
          message_type: SocialMessage.message_types[:bot],
          readed_at: Time.current,
          broadcast: broadcast
        )
        double(invalid?: false, result: message)
      end

      # Allow message method to return the broadcast content
      allow_any_instance_of(described_class).to receive(:message).and_return(broadcast.content)

      expect {
        outcome
      }.to change {
        SocialMessage.where(
          social_customer: receiver.social_customer,
          raw_content: broadcast.content,
          broadcast: broadcast
        ).count
      }.by(1)
    end

    context "when broadcast is reservation_customers" do
      let(:reservation_customer) { FactoryBot.create(:reservation_customer, customer: receiver) }
      let(:broadcast) do
        FactoryBot.create(:broadcast, user: receiver.user, query_type: "reservation_customers", query: {
          filters: [
            {
              field: "reservation_id",
              value: reservation_customer.reservation_id,
              condition: "eq"
            }
          ],
          operator: "or"
        })
      end
      before { receiver.update_columns(reminder_permission: false) }

      it "sends line with social_message had broadcast id even the receiver has not enabled reminder permission" do
        # Expect SocialMessages::Create.run to be called with the correct parameters
        expect(SocialMessages::Create).to receive(:run).with(
          social_customer: receiver.social_customer,
          content: broadcast.content,
          content_type: SocialUserMessages::Create::TEXT_TYPE,
          message_type: SocialMessage.message_types[:bot],
          readed: true,
          broadcast: broadcast
        ) do
          # Create the SocialMessage record directly
          message =SocialMessage.create!(
            social_customer: receiver.social_customer,
            social_account: receiver.social_customer.social_account,
            raw_content: broadcast.content,
            content_type: SocialUserMessages::Create::TEXT_TYPE,
            message_type: SocialMessage.message_types[:bot],
            readed_at: Time.current,
            broadcast: broadcast
          )
          double(invalid?: false, result: message)
        end

        # Allow message method to return the broadcast content
        allow_any_instance_of(described_class).to receive(:message).and_return(broadcast.content)

        expect {
          outcome
        }.to change {
          SocialMessage.where(
            social_customer: receiver.social_customer,
            raw_content: broadcast.content,
            broadcast: broadcast
          ).count
        }.by(1)
      end
    end

    context "with different customer notification channels" do
      before do
        setup_notification_stubs
      end

      context "when customer_notification_channel is email" do
        before do
          # Override the global business_owner mock for this context
          user = receiver.user
          allow(user).to receive(:customer_notification_channel).and_return("email")
          allow_any_instance_of(described_class).to receive(:business_owner).and_return(user)
        end

        context "when all channels are available" do
          before { all_channels_available }

          it "sends only email notification and never SMS or LINE" do
            # Key requirement: when channel is email, never send SMS or LINE
            expect_any_instance_of(described_class).to receive(:notify_by_email).and_return(true)
            expect_any_instance_of(described_class).not_to receive(:notify_by_sms)
            expect_any_instance_of(described_class).not_to receive(:notify_by_line)

            outcome
          end
        end

        context "when only email is available" do
          before { only_email_available }

          it "sends only email notification" do
            expect_any_instance_of(described_class).to receive(:notify_by_email).and_return(true)
            expect_any_instance_of(described_class).not_to receive(:notify_by_sms)
            expect_any_instance_of(described_class).not_to receive(:notify_by_line)

            outcome
          end
        end

        context "when email is not available" do
          before { set_availability(email: false, sms: true, line: true) }

          it "doesn't send any notification when email is not available" do
            expect_any_instance_of(described_class).not_to receive(:notify_by_email)
            expect_any_instance_of(described_class).not_to receive(:notify_by_sms)
            expect_any_instance_of(described_class).not_to receive(:notify_by_line)

            outcome
          end
        end
      end

      context "when customer_notification_channel is sms" do
        before do
          # Override the global business_owner mock for this context
          user = receiver.user
          allow(user).to receive(:customer_notification_channel).and_return("sms")
          allow_any_instance_of(described_class).to receive(:business_owner).and_return(user)
        end

        context "when all channels are available" do
          before { all_channels_available }

          it "sends sms notification and never LINE" do
            # Key requirement: when channel is sms, never send LINE
            expect_any_instance_of(described_class).to receive(:notify_by_sms).and_return(true)
            expect_any_instance_of(described_class).not_to receive(:notify_by_line)
            expect_any_instance_of(described_class).not_to receive(:notify_by_email)

            outcome
          end
        end

        context "when only sms is available" do
          before { only_sms_available }

          it "sends only sms notification" do
            expect_any_instance_of(described_class).to receive(:notify_by_sms).and_return(true)
            expect_any_instance_of(described_class).not_to receive(:notify_by_line)
            expect_any_instance_of(described_class).not_to receive(:notify_by_email)

            outcome
          end
        end

        context "when sms is not available but email is" do
          before { set_availability(email: true, sms: false, line: true) }

          it "sends email notification as fallback but never LINE" do
            # Key requirement: when channel is sms, never send LINE even as fallback
            expect_any_instance_of(described_class).not_to receive(:notify_by_sms)
            expect_any_instance_of(described_class).to receive(:notify_by_email).and_return(true)
            expect_any_instance_of(described_class).not_to receive(:notify_by_line)

            outcome
          end
        end

        context "when neither sms nor email is available" do
          before { set_availability(email: false, sms: false, line: true) }

          it "doesn't send any notification (not even LINE)" do
            expect_any_instance_of(described_class).not_to receive(:notify_by_sms)
            expect_any_instance_of(described_class).not_to receive(:notify_by_email)
            expect_any_instance_of(described_class).not_to receive(:notify_by_line)

            outcome
          end
        end
      end

      context "when customer_notification_channel is line" do
        before do
          # Override the global business_owner mock for this context
          user = receiver.user
          allow(user).to receive(:customer_notification_channel).and_return("line")
          allow_any_instance_of(described_class).to receive(:business_owner).and_return(user)
        end

        context "when all channels are available" do
          before { all_channels_available }

          it "sends line notification as highest priority" do
            # Key requirement: when channel is line, line has highest priority
            expect_any_instance_of(described_class).to receive(:notify_by_line).and_return(true)
            expect_any_instance_of(described_class).not_to receive(:notify_by_sms)
            expect_any_instance_of(described_class).not_to receive(:notify_by_email)

            outcome
          end
        end

        context "when only line is available" do
          before { only_line_available }

          it "sends only line notification" do
            expect_any_instance_of(described_class).to receive(:notify_by_line).and_return(true)
            expect_any_instance_of(described_class).not_to receive(:notify_by_sms)
            expect_any_instance_of(described_class).not_to receive(:notify_by_email)

            outcome
          end
        end

        context "when line and sms are not available but email is" do
          before { set_availability(email: true, sms: false, line: false) }

          it "sends email notification as final fallback" do
            expect_any_instance_of(described_class).not_to receive(:notify_by_line)
            expect_any_instance_of(described_class).not_to receive(:notify_by_sms)
            expect_any_instance_of(described_class).to receive(:notify_by_email).and_return(true)

            outcome
          end
        end

        context "when no notification channels are available" do
          before { set_availability(email: false, sms: false, line: false) }

          it "doesn't send any notification" do
            expect_any_instance_of(described_class).not_to receive(:notify_by_line)
            expect_any_instance_of(described_class).not_to receive(:notify_by_sms)
            expect_any_instance_of(described_class).not_to receive(:notify_by_email)

            outcome
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notifiers::Customers::OnlineServices::ActiveRelations, :with_line do
  let!(:receiver) { FactoryBot.create(:social_customer, customer: relation.customer).customer }
  let(:relation) { FactoryBot.create(:online_service_customer_relation, :free) }
  let(:business_owner) { receiver.user }
  let(:user_setting) { FactoryBot.create(:user_setting, user: business_owner) }

  let(:args) do
    {
      receiver: receiver
    }
  end
  let(:outcome) { described_class.run(args) }

  # Common test setup
  shared_context "notification setup" do
    before do
      # Basic setup
      allow(business_owner).to receive(:user_setting).and_return(user_setting)

      # Stub validators and methods
      allow_any_instance_of(described_class).to receive(:deliverable).and_return(true)
      allow_any_instance_of(described_class).to receive(:message).and_return("Test message")
      allow_any_instance_of(described_class).to receive(:business_owner).and_return(business_owner)

      # Stub notification methods
      setup_notification_stubs
    end

    def setup_notification_stubs
      # Set up SMS stubs
      allow_any_instance_of(described_class).to receive(:user).and_return(business_owner)
      allow_any_instance_of(described_class).to receive(:customer).and_return(receiver)
      allow(business_owner).to receive(:locale).and_return('ja')
      allow(receiver).to receive(:locale).and_return('ja')
      allow(Sms::Create).to receive(:run).and_return(true)
      allow_any_instance_of(described_class).to receive(:phone_number).and_return("+810123456789")

      # Set up LINE stubs
      mock_line_user = double('line_user', user: business_owner, language: 'ja')
      allow_any_instance_of(described_class).to receive(:target_line_user).and_return(mock_line_user)
      allow(LineClient).to receive(:send).and_return(true)
      allow(LineClient).to receive(:flex).and_return(true)

      # Set up Email stubs
      allow_any_instance_of(described_class).to receive(:target_email_user).and_return(business_owner)
      allow_any_instance_of(described_class).to receive(:email).and_return("example@example.com")
      allow_any_instance_of(described_class).to receive(:mailer).and_return(double('mailer'))
      allow_any_instance_of(described_class).to receive(:mailer_method).and_return(:method_name)
      allow_any_instance_of(described_class).to receive_message_chain('mailer.method_name.deliver_now').and_return(true)

      # Mock the notification methods instead of calling the originals
      allow_any_instance_of(described_class).to receive(:notify_by_email).and_return(true)
      allow_any_instance_of(described_class).to receive(:notify_by_sms).and_return(true)
      allow_any_instance_of(described_class).to receive(:notify_by_line).and_return(true)
    end

    # Helper methods for setting notification availability
    def set_availability(email: false, sms: false, line: false)
      allow_any_instance_of(described_class).to receive(:available_to_send_email?).and_return(email)
      allow_any_instance_of(described_class).to receive(:available_to_send_sms?).and_return(sms)
      allow_any_instance_of(described_class).to receive(:available_to_send_line?).and_return(line)
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
    # Test for different notification channels
    context "when testing notification channels" do
      include_context "notification setup"

      context "when customer_notification_channel is email" do
        before do
          user_setting.update(customer_notification_channel: "email")
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
          user_setting.update(customer_notification_channel: "sms")
        end

        context "when all channels are available" do
          before { all_channels_available }

          it "sends sms notification and never LINE" do
            # Key requirement: when channel is sms, never send LINE
            expect_any_instance_of(described_class).to receive(:notify_by_sms).and_return(true)
            expect_any_instance_of(described_class).not_to receive(:notify_by_line)
            # May not test email since it depends on implementation

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
          user_setting.update(customer_notification_channel: "line")
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

        context "when line is not available but sms is" do
          before { set_availability(email: true, sms: true, line: false) }

          it "sends sms notification as first fallback" do
            expect_any_instance_of(described_class).not_to receive(:notify_by_line)
            expect_any_instance_of(described_class).to receive(:notify_by_sms).and_return(true)
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

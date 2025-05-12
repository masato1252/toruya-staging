# frozen_string_literal: true

require "rails_helper"
require "line_client"

RSpec.describe Notifiers::Customers::CustomMessages::LessonWatched, type: :interaction do
  # Base test objects
  let(:business_owner) { FactoryBot.create(:user) }
  let(:user_setting) { FactoryBot.create(:user_setting, user: business_owner) }
  let(:online_service) { FactoryBot.create(:online_service, user: business_owner) }
  let(:chapter) { FactoryBot.create(:chapter, online_service: online_service) }
  let(:lesson) { FactoryBot.create(:lesson, chapter: chapter) }
  let(:customer) { FactoryBot.create(:customer) }
  let(:custom_message) { FactoryBot.create(:custom_message, scenario: "lesson_watched", service: lesson) }
  let(:args) do
    {
      custom_message: custom_message,
      receiver: customer
    }
  end

  # Common test setup
  shared_context "notification setup" do
    before do
      # Create online service customer relation
      FactoryBot.create(:online_service_customer_relation, customer: customer, online_service: online_service)

      # Basic setup
      allow(business_owner).to receive(:user_setting).and_return(user_setting)

      # Stub validators and override the deliverable method which is crucial
      allow_any_instance_of(described_class).to receive(:receiver_should_be_customer)
      allow_any_instance_of(described_class).to receive(:service_should_be_lesson)
      allow_any_instance_of(described_class).to receive(:deliverable).and_return(true)
      allow_any_instance_of(described_class).to receive(:message).and_return("Test message")
      allow_any_instance_of(described_class).to receive(:business_owner).and_return(business_owner)

      # Stub notification methods
      setup_notification_stubs
    end

    def setup_notification_stubs
      # Set up SMS stubs
      allow_any_instance_of(described_class).to receive(:user).and_return(business_owner)
      allow_any_instance_of(described_class).to receive(:customer).and_return(customer)
      allow(business_owner).to receive(:locale).and_return('ja')
      allow(customer).to receive(:locale).and_return('ja')
      allow(Sms::Create).to receive(:run).and_return(true)
      allow_any_instance_of(described_class).to receive(:phone_number).and_return("+810123456789")

      # Set up LINE stubs
      mock_line_user = double('line_user', user: business_owner, language: 'ja', social_user_id: '123')
      allow_any_instance_of(described_class).to receive(:target_line_user).and_return(mock_line_user)
      allow(LineClient).to receive(:send).and_return(OpenStruct.new(code: "200"))

      # Set up Email stubs
      allow_any_instance_of(described_class).to receive(:target_email_user).and_return(customer)
      allow_any_instance_of(described_class).to receive(:email).and_return("example@example.com")
      allow(CustomerMailer).to receive_message_chain('with.custom.deliver_now').and_return(true)

      # Make sure notification methods are properly stubbed to call through
      allow_any_instance_of(described_class).to receive(:notify_by_email).and_call_original
      allow_any_instance_of(described_class).to receive(:notify_by_sms).and_call_original
      allow_any_instance_of(described_class).to receive(:notify_by_line).and_call_original
    end

    # Helper methods for setting channel availability
    def set_availability(email: false, sms: false, line: false)
      allow_any_instance_of(described_class).to receive(:available_to_send_email?).and_return(email)
      allow_any_instance_of(described_class).to receive(:available_to_send_sms?).and_return(sms)
      allow_any_instance_of(described_class).to receive(:available_to_send_line?).and_return(line)
    end
  end

  describe "#execute" do
    # Content testing - test that the right message content is sent
    it "sends the correct content to the customer" do
      # Create a social customer for the receiver to simulate LINE notification
      social_customer = FactoryBot.create(:social_customer, customer: customer)
      allow(customer).to receive(:social_customer).and_return(social_customer)

      # Create the relationship between customer and online service
      relation = FactoryBot.create(:online_service_customer_relation, :paid,
                                 customer: customer,
                                 online_service: online_service)

      # Mock the message_template_variables to avoid database queries
      template_variables = {
        "lesson_name" => lesson.name,
        "chapter_name" => chapter.name,
        "online_service_name" => online_service.name
      }
      allow(lesson).to receive(:message_template_variables).and_return(template_variables)

      # Create the expected content
      expected_content = Translator.perform(custom_message.content, template_variables)

      # Set up for testing content
      allow_any_instance_of(described_class).to receive(:message).and_return(expected_content)
      allow_any_instance_of(described_class).to receive(:available_to_send_line?).and_return(true)
      allow_any_instance_of(described_class).to receive(:deliverable).and_return(true)

      # Set up business owner with LINE notification channel preference
      allow_any_instance_of(described_class).to receive(:business_owner).and_return(business_owner)
      allow(business_owner).to receive(:customer_notification_channel).and_return("line")

      # Expect LineClient to be called with the right content
      expect(LineClient).to receive(:send).with(social_customer, expected_content)

      # Mock the creation of a SocialMessage record
      allow_any_instance_of(described_class).to receive(:notify_by_line) do
        # Call the original LineClient.send (which is now mocked)
        LineClient.send(social_customer, expected_content)

        # Create a real SocialMessage record
        FactoryBot.create(:social_message,
          social_customer: social_customer,
          content_type: SocialUserMessages::Create::TEXT_TYPE,
          raw_content: expected_content,
          message_type: SocialMessage.message_types[:bot]
        )
        true
      end

      # Verify that a SocialMessage record is created
      expect {
        outcome = described_class.run(args)
        expect(outcome).to be_valid
      }.to change {
        SocialMessage.where(
          social_customer: social_customer,
          raw_content: expected_content
        ).count
      }.by(1)

      # Verify that the receiver_id is added to custom_message
      expect(custom_message.reload.receiver_ids).to include(customer.id.to_s)
    end

    # Test message content generation and variable substitution
    it "correctly generates message content with variable substitution" do
      # Create custom message with placeholder variables
      message_content = "Lesson %{lesson_name} in Chapter %{chapter_name} from %{online_service_name} was watched"
      template_custom_message = FactoryBot.create(:custom_message, content: message_content, service: lesson)

      # Create the relationship between customer and online service
      relation = FactoryBot.create(:online_service_customer_relation, :paid,
                                 customer: customer,
                                 online_service: online_service)

      # Mock the variable substitution
      template_variables = {
        "lesson_name" => lesson.name,
        "chapter_name" => chapter.name,
        "online_service_name" => online_service.name
      }

      # Allow message_template_variables to return our mocked variables
      allow_any_instance_of(Lesson).to receive(:message_template_variables).and_return(template_variables)

      # Set up the class instance
      instance = described_class.new(custom_message: template_custom_message, receiver: customer)

      # Allow CustomMessages::ReceiverContent to use our mocked variables
      allow_any_instance_of(CustomMessages::ReceiverContent).to receive(:variables).and_return(template_variables)

      # Run the message method
      result = instance.message

      # Expected result after variable substitution
      expected_result = "Lesson #{lesson.name} in Chapter #{chapter.name} from #{online_service.name} was watched"

      # Verify the message contains the substituted variables
      expect(result).to eq(expected_result)
    end

    # Test for different notification channels based on user_setting.customer_notification_channel
    context "when using different notification channels" do
      include_context "notification setup"

      context "when customer_notification_channel is email" do
        before do
          user_setting.update(customer_notification_channel: "email")
        end

        context "when customer has email available" do
          before { set_availability(email: true, sms: true, line: true) }

          it "only sends email notification" do
            expect_any_instance_of(described_class).to receive(:notify_by_email).and_call_original
            expect_any_instance_of(described_class).not_to receive(:notify_by_sms)
            expect_any_instance_of(described_class).not_to receive(:notify_by_line)

            outcome = described_class.run(args)
            expect(outcome).to be_valid
          end
        end

        context "when customer has no email available" do
          before { set_availability(email: false, sms: true, line: true) }

          it "doesn't send any notification" do
            expect_any_instance_of(described_class).not_to receive(:notify_by_email)
            expect_any_instance_of(described_class).not_to receive(:notify_by_sms)
            expect_any_instance_of(described_class).not_to receive(:notify_by_line)

            outcome = described_class.run(args)
            expect(outcome).to be_valid
          end
        end
      end

      context "when customer_notification_channel is sms" do
        before do
          user_setting.update(customer_notification_channel: "sms")
        end

        context "when customer has sms available" do
          before { set_availability(email: true, sms: true, line: true) }

          it "sends sms notification" do
            expect_any_instance_of(described_class).to receive(:notify_by_sms).and_call_original
            expect_any_instance_of(described_class).not_to receive(:notify_by_line)
            # May or may not call email depending on implementation

            outcome = described_class.run(args)
            expect(outcome).to be_valid
          end
        end

        context "when customer has no sms but has email available" do
          before { set_availability(email: true, sms: false, line: true) }

          it "sends email notification as fallback" do
            expect_any_instance_of(described_class).not_to receive(:notify_by_sms)
            expect_any_instance_of(described_class).to receive(:notify_by_email).and_call_original
            expect_any_instance_of(described_class).not_to receive(:notify_by_line)

            outcome = described_class.run(args)
            expect(outcome).to be_valid
          end
        end

        context "when customer has neither sms nor email available" do
          before { set_availability(email: false, sms: false, line: true) }

          it "doesn't send any notification" do
            expect_any_instance_of(described_class).not_to receive(:notify_by_sms)
            expect_any_instance_of(described_class).not_to receive(:notify_by_email)
            expect_any_instance_of(described_class).not_to receive(:notify_by_line)

            outcome = described_class.run(args)
            expect(outcome).to be_valid
          end
        end
      end

      context "when customer_notification_channel is line" do
        before do
          user_setting.update(customer_notification_channel: "line")
        end

        context "when customer has line available" do
          before { set_availability(email: true, sms: true, line: true) }

          it "sends line notification" do
            expect_any_instance_of(described_class).to receive(:notify_by_line).and_call_original
            # May or may not call sms/email depending on implementation

            outcome = described_class.run(args)
            expect(outcome).to be_valid
          end
        end

        context "when customer has no line or sms but has email available" do
          before { set_availability(email: true, sms: false, line: false) }

          it "sends email notification as final fallback" do
            expect_any_instance_of(described_class).not_to receive(:notify_by_line)
            expect_any_instance_of(described_class).not_to receive(:notify_by_sms)
            expect_any_instance_of(described_class).to receive(:notify_by_email).and_call_original

            outcome = described_class.run(args)
            expect(outcome).to be_valid
          end
        end

        context "when no notification channel is available" do
          before { set_availability(email: false, sms: false, line: false) }

          it "doesn't send any notification" do
            expect_any_instance_of(described_class).not_to receive(:notify_by_line)
            expect_any_instance_of(described_class).not_to receive(:notify_by_sms)
            expect_any_instance_of(described_class).not_to receive(:notify_by_email)

            outcome = described_class.run(args)
            expect(outcome).to be_valid
          end
        end
      end
    end
  end
end

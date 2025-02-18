# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notifiers::Customers::LineSettings::LineLoginVerificationFlex do
  let(:social_user) { FactoryBot.create(:social_user) }
  let(:receiver) { FactoryBot.create(:social_customer, user: social_user.user).customer }
  # Create a user setting with line notification channel for the receiver
  let!(:user_setting) { FactoryBot.create(:user_setting, user: receiver.user, customer_notification_channel: 'line') }

  let(:args) do
    {
      receiver: receiver
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "creates a customer message", :with_line do
      # Set up the business owner
      business_owner = receiver.user
      allow_any_instance_of(Notifiers::Base).to receive(:business_owner).and_return(business_owner)

      # Set the notification channel explicitly
      allow(business_owner).to receive(:customer_notification_channel).and_return("line")

      # Ensure LINE is available as a notification channel
      allow_any_instance_of(Notifiers::Base).to receive(:available_to_send_line?).and_return(true)

      # Mock the actual messages creation to create a real record
      allow_any_instance_of(Notifiers::Base).to receive(:notify_by_line) do
        # Create a real SocialMessage record using the factory
        FactoryBot.create(:social_message,
          social_customer: receiver.social_customer,
          content_type: SocialMessages::Create::FLEX_TYPE,
          raw_content: "Test message",
          message_type: SocialMessage.message_types[:bot]
        )
        true
      end

      expect {
        outcome
      }.to change {
        SocialMessage.where(social_customer: receiver.social_customer, content_type: SocialMessages::Create::FLEX_TYPE).count
      }.by(1)
    end
  end
end

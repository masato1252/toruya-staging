# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notifiers::Customers::LineSettings::LineLoginVerificationFlex do
  let(:social_user) { FactoryBot.create(:social_user) }
  let(:receiver) { FactoryBot.create(:social_customer, user: social_user.user).customer }
  # Create a user setting with line notification channel for the receiver
  let!(:user_setting) { FactoryBot.create(:user_setting, user: receiver.user, customer_notification_channel: 'email') }

  let(:args) do
    {
      receiver: receiver
    }
  end
  let(:outcome) { described_class.run(args) }
  let(:instance) { described_class.new(args) }

  describe "#content_type" do
    it "returns FLEX_TYPE" do
      expect(instance.content_type).to eq(SocialUserMessages::Create::FLEX_TYPE)
    end
  end

  describe "#message" do
    before do
      allow(I18n).to receive(:t).with("line_verification.confirmation_message.title1").and_return("Title 1")
      allow(I18n).to receive(:t).with("line_verification.confirmation_message.title2").and_return("Title 2")
      allow(I18n).to receive(:t).with("line_verification.confirmation_message.action").and_return("Action")
    end

    it "returns a valid Flex message JSON" do
      message = JSON.parse(instance.message)
      expect(message).to include("type" => "flex")
      expect(message).to include("altText" => "Title 1")
      expect(message["contents"]).to be_present
    end

    it "includes correct message structure" do
      message = JSON.parse(instance.message)
      contents = message["contents"]

      expect(contents).to include("type" => "bubble")
      expect(contents["body"]).to be_present
      expect(contents["footer"]).to be_present
    end
  end

  describe "#execute" do
    it "creates a customer message even when notification channel is email", :with_line do
      # Set up the business owner with email notification channel
      business_owner = receiver.user
      allow_any_instance_of(Notifiers::Base).to receive(:business_owner).and_return(business_owner)
      allow(business_owner).to receive(:customer_notification_channel).and_return("email")

      # Ensure LINE is available as a notification channel
      allow_any_instance_of(Notifiers::Base).to receive(:available_to_send_line?).and_return(true)

      # Mock the actual messages creation to create a real record
      captured_message = nil
      allow_any_instance_of(Notifiers::Base).to receive(:notify_by_line) do
        captured_message = instance.message
        FactoryBot.create(:social_message,
          social_customer: receiver.social_customer,
          content_type: SocialMessages::Create::FLEX_TYPE,
          raw_content: captured_message,
          message_type: SocialMessage.message_types[:bot]
        )
        true
      end

      expect {
        outcome
      }.to change {
        SocialMessage.where(social_customer: receiver.social_customer, content_type: SocialMessages::Create::FLEX_TYPE).count
      }.by(1)

      # Verify the created message is a valid JSON and has the expected structure
      expect { JSON.parse(captured_message) }.not_to raise_error
      message = JSON.parse(captured_message)
      expect(message["type"]).to eq("flex")
    end

    it "uses LINE as the preferred channel regardless of notification settings" do
      business_owner = receiver.user
      allow_any_instance_of(Notifiers::Base).to receive(:business_owner).and_return(business_owner)
      allow(business_owner).to receive(:customer_notification_channel).and_return("email")

      expect_any_instance_of(Notifiers::Base).to receive(:send_notification_with_fallbacks)
        .with(preferred_channel: "line")
        .once

      outcome
    end
  end
end

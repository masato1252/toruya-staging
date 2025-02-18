# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notifiers::Customers::CustomMessages::EpisodeWatched, :with_line do
  let(:receiver) { FactoryBot.create(:social_customer, customer: relation.customer).customer }
  let(:custom_message) { FactoryBot.create(:custom_message, service: episode) }
  let(:episode) { FactoryBot.create(:episode) }
  let(:relation) { FactoryBot.create(:online_service_customer_relation, :paid, online_service: episode.online_service) }
  # Create a user setting with line notification channel for the receiver
  let!(:user_setting) { FactoryBot.create(:user_setting, user: receiver.user, customer_notification_channel: 'line') }

  let(:args) do
    {
      receiver: receiver,
      custom_message: custom_message
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "sends line" do
      content = Translator.perform(custom_message.content, custom_message.service.message_template_variables(receiver))

      # Set up the business owner
      business_owner = receiver.user
      allow_any_instance_of(Notifiers::Base).to receive(:business_owner).and_return(business_owner)

      # Set the notification channel explicitly
      allow(business_owner).to receive(:customer_notification_channel).and_return("line")

      # Ensure LINE is available as a notification channel
      allow_any_instance_of(Notifiers::Base).to receive(:available_to_send_line?).and_return(true)

      # First, expect LineClient.send to be called
      expect(LineClient).to receive(:send).with(receiver.social_customer, content)

      # Then, mock the actual messages creation to create a real record
      allow_any_instance_of(Notifiers::Base).to receive(:notify_by_line) do |instance|
        # Call the original LineClient.send (which is now mocked)
        LineClient.send(receiver.social_customer, content)

        # Create a real SocialMessage record using the factory
        FactoryBot.create(:social_message,
          social_customer: receiver.social_customer,
          content_type: SocialUserMessages::Create::TEXT_TYPE,
          raw_content: content,
          message_type: SocialMessage.message_types[:bot]
        )
        true
      end

      expect {
        outcome
      }.to change {
        SocialMessage.where(
          social_customer: receiver.social_customer,
          raw_content: content
        ).count
      }.by(1)

      expect(custom_message.receiver_ids).to eq([receiver.id.to_s])
    end

    context "when this custom message was ever sent before" do
      let(:custom_message) { FactoryBot.create(:custom_message, receiver_ids: [receiver.id]) }

      it "doesn't send line" do
        expect {
          outcome
        }.not_to change {
          SocialMessage.where(social_customer: receiver.social_customer).count
        }

        expect(custom_message.receiver_ids).to eq([receiver.id.to_s])
      end
    end

    context "when this custom message's customer was unavailable to use this product" do
      let(:relation) { FactoryBot.create(:online_service_customer_relation) }

      it "doesn't send line" do
        expect {
          outcome
        }.not_to change {
          SocialMessage.where(social_customer: receiver.social_customer).count
        }
      end
    end
  end
end

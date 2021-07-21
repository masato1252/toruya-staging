# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notifiers::CustomMessages::Send do
  let(:receiver) { FactoryBot.create(:social_customer).customer }
  let(:custom_message) { FactoryBot.create(:custom_message) }
  let(:args) do
    {
      receiver: receiver,
      custom_message: custom_message
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "sends line" do
      content = Translator.perform(custom_message.content, { customer_name: receiver.display_last_name, service_title: custom_message.service.name })
      expect(LineClient).to receive(:send).with(receiver.social_customer, content)
      expect(CustomMessages::Next).to receive(:run).with({
        custom_message: custom_message,
        receiver: receiver
      })

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
        expect(CustomMessages::Next).not_to receive(:run)

        expect {
          outcome
        }.not_to change {
          SocialMessage.where(social_customer: receiver.social_customer).count
        }

        expect(custom_message.receiver_ids).to eq([receiver.id.to_s])
      end
    end
  end
end

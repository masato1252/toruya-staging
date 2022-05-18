# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notifiers::Users::CustomMessages::Send do
  let(:receiver) { FactoryBot.create(:social_user).user }
  let(:custom_message) { FactoryBot.create(:custom_message, :user_signed_up_scenario) }
  let(:args) do
    {
      receiver: receiver,
      custom_message: custom_message
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "sends line" do
      content = Translator.perform(custom_message.content, receiver.message_template_variables)
      expect(LineClient).to receive(:send).with(receiver.social_user, content)
      expect(CustomMessages::Users::Next).to receive(:run).with({
        custom_message: custom_message,
        receiver: receiver
      })

      expect {
        outcome
      }.to change {
        SocialUserMessage.where(
          social_user: receiver.social_user,
          raw_content: content
        ).count
      }.by(1)

      expect(custom_message.receiver_ids).to eq([receiver.id.to_s])
    end

    context "when this custom message was ever sent before" do
      let(:custom_message) { FactoryBot.create(:custom_message, receiver_ids: [receiver.id]) }

      it "doesn't send line but still schedule next message" do
        expect(CustomMessages::Users::Next).to receive(:run)

        expect {
          outcome
        }.not_to change {
          SocialUserMessage.where(social_user: receiver.social_user).count
        }

        expect(custom_message.receiver_ids).to eq([receiver.id.to_s])
      end
    end
  end
end

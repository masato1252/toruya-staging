# frozen_string_literal: true

require "rails_helper"

RSpec.describe CustomMessages::Next do
  let(:receiver) { FactoryBot.create(:social_customer, user: user).customer }
  let(:user) { custom_message.service.user }
  let(:custom_message) { FactoryBot.create(:custom_message) }
  let(:args) do
    {
      receiver: receiver,
      custom_message: custom_message
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when there is next custom message" do
      it "schedules the next custom message" do
        next_custom_message = FactoryBot.create(
          :custom_message,
          service: custom_message.service,
          scenario: custom_message.scenario,
          position: custom_message.position + 1
        )

        expect(Notifiers::CustomMessages::Send).to receive(:perform_at).with({
          schedule_at: Time.current.advance(days: next_custom_message.after_last_message_days).change(hour: 9),
          custom_message: next_custom_message,
          receiver: receiver
        })

        outcome
      end
    end

    context "when there is NO next custom message" do
      it "does nothing" do
        expect(Notifiers::CustomMessages::Send).not_to receive(:perform_at)

        outcome
      end
    end
  end
end

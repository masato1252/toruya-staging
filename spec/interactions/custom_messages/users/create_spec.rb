# frozen_string_literal: true

require "rails_helper"

RSpec.describe CustomMessages::Users::Create do
  let(:content) { "foo" }
  let(:scenario) { CustomMessages::Users::Template::USER_SIGN_UP }
  let(:after_days) { 0 }
  let(:content_type) { CustomMessage::TEXT_TYPE }
  let(:args) do
    {
      content: content,
      scenario: scenario,
      after_days: after_days,
      content_type: content_type
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "creates a custom_message" do
      expect {
        outcome
      }.to change {
        CustomMessage.where(service: nil, scenario: scenario, after_days: after_days).count
      }.by(1)

      message = CustomMessage.find_by(service: nil, scenario: scenario, after_days: after_days)
      expect(message.receiver_ids).to eq([])
    end
  end
end

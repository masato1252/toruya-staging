# frozen_string_literal: true

require "rails_helper"

RSpec.describe CustomMessages::Create do
  let(:user) { FactoryBot.create(:user) }
  let(:service) { FactoryBot.create(:online_service, user: user) }
  let(:template) { "foo" }
  let(:scenario) { CustomMessage::ONLINE_SERVICE_PURCHASED }
  let(:after_days) { 3 }
  let(:args) do
    {
      service: service,
      template: template,
      scenario: scenario,
      after_days: after_days,
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "creates a custom_message" do
      expect {
        outcome
      }.to change {
        CustomMessage.where(service: service, scenario: scenario, position: position).count
      }.by(1)
    end
  end
end

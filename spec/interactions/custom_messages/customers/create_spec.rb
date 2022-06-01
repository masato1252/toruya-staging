# frozen_string_literal: true

require "rails_helper"

RSpec.describe CustomMessages::Customers::Create do
  let(:service) { relation.online_service }
  let(:content) { "foo" }
  let(:scenario) { CustomMessages::Customers::Template::ONLINE_SERVICE_PURCHASED }
  let!(:relation) { FactoryBot.create(:online_service_customer_relation, :free) }
  let(:after_days) { nil }
  let(:args) do
    {
      service: service,
      content: content,
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
        CustomMessage.where(service: service, scenario: scenario, after_days: after_days).count
      }.by(1)

      message = CustomMessage.find_by(service: service, scenario: scenario, after_days: after_days)
      expect(message.receiver_ids).to eq([])
    end

    context "when new message's after_days is nil" do
      let(:after_days) { nil }

      it "creates a custom_message" do
        expect(CustomMessages::Customers::Next).not_to receive(:perform_later)

        outcome
      end
    end

    context "when new message's after_days is not nil or 0" do
      let(:after_days) { 1 }

      it "schedules to send all the available customers" do
        allow(CustomMessages::Customers::Next).to receive(:perform_later)

        result = outcome.result

        expect(CustomMessages::Customers::Next).to have_received(:perform_later).with({
          custom_message: result,
          receiver: relation.customer,
          schedule_right_away: true
        })
      end
    end
  end
end

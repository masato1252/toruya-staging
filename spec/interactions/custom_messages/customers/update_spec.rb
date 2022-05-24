# frozen_string_literal: true

require "rails_helper"

RSpec.describe CustomMessages::Customers::Update do
  let!(:relation) { FactoryBot.create(:online_service_customer_relation, :free) }
  let(:service) { relation.online_service }
  let(:custom_message) { FactoryBot.create(:custom_message, service: service, after_days: nil) }
  let(:template) { "foo" }
  let(:after_days) { nil }
  let(:args) do
    {
      message: custom_message,
      template: template,
      after_days: after_days,
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    let(:template) { "bar" }
    let(:after_days) { 3 }

    it "updates a custom_message" do
      outcome

      expect(custom_message.content).to eq(template)
      expect(custom_message.after_days).to eq(after_days)
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

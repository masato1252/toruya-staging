# frozen_string_literal: true

require "rails_helper"

RSpec.describe CustomMessages::Update do
  let(:user) { FactoryBot.create(:user) }
  let(:service) { FactoryBot.create(:online_service, user: user) }
  let(:template) { "foo" }
  let(:scenario) { CustomMessage::ONLINE_SERVICE_PURCHASED }
  let(:position) { 0 }
  let(:after_last_message_days) { 3 }
  let(:args) do
    {
      service: service,
      template: template,
      scenario: scenario,
      position: position,
      after_last_message_days: after_last_message_days,
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "position == 0(sent when customers purchased/booked)" do
      it "creates a custom_message" do
        expect {
          outcome
        }.to change {
          CustomMessage.where(service: service, scenario: scenario, position: position).count
        }.by(1)
      end
    end

    context "position == 1" do
      let(:position) { 1 }

      it "creates a custom_message and send messages to existing customers" do
        relation = FactoryBot.create(:online_service_customer_relation, :free, online_service: service)
        allow(Notifiers::CustomMessages::Send).to receive(:perform_later)

        custom_message = outcome.result

        expect(Notifiers::CustomMessages::Send).to have_received(:perform_later).with({
          custom_message: custom_message,
          receiver: relation.customer
        })
      end
    end

    context "position > 1" do
      let(:position) { 2 }

      it "creates a custom_message and send messages to customers who already received latest message" do
        customer = FactoryBot.create(:customer)
        FactoryBot.create(:custom_message, service: service, scenario: scenario, position: 1, receiver_ids: [customer.id])
        FactoryBot.create(:online_service_customer_relation, :free, online_service: service, customer: customer)
        allow(CustomMessages::Next).to receive(:perform_later)

        custom_message = outcome.result

        expect(CustomMessages::Next).to have_received(:perform_later).with({
          custom_message: custom_message,
          receiver: customer
        })
      end
    end
  end
end

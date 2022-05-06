# frozen_string_literal: true

require "rails_helper"

RSpec.describe StripeEvents::PaymentSucceed do
  before { StripeMock.start }
  after { StripeMock.stop }
  let(:subscription) { FactoryBot.create(:subscription, :with_stripe) }
  let(:customer) { FactoryBot.create(:customer, user: subscription.user, with_stripe: true) }
  let(:relation) { FactoryBot.create(:online_service_customer_relation, :monthly_payment, :stripe_subscribed, customer: customer) }
  let(:event) { StripeMock.mock_webhook_event('invoice.payment_succeeded', {
    subscription: relation.stripe_subscription_id,
    billing_reason: "subscription_cycle"
  }) }
  let(:args) do
    {
      event: event
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "creates a completed payment" do
      allow(Notifiers::Customers::CustomerPayments::NotFirstTimeChargeSuccessfully).to receive(:run)

      expect {
        outcome
      }.to change {
        customer.customer_payments.where(order_id: event.data.object.id).count
      }.by(1)

      expect(outcome.result).to have_attributes(
        amount_cents: event.data.object.total,
        amount_currency: Money.default_currency.iso_code,
        order_id: event.data.object.id,
        state: "completed"
      )
      expect(Notifiers::Customers::CustomerPayments::NotFirstTimeChargeSuccessfully).to have_received(:run).with(
        receiver: outcome.result.customer,
        customer_payment: outcome.result,
      )
    end
  end
end

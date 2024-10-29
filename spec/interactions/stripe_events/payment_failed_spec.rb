# frozen_string_literal: true

require "rails_helper"

RSpec.describe StripeEvents::PaymentFailed do
  before { StripeMock.start }
  after { StripeMock.stop }
  let(:subscription) { FactoryBot.create(:subscription, :with_stripe) }
  let(:customer) { FactoryBot.create(:customer, user: subscription.user, with_stripe: true) }
  let(:relation) { FactoryBot.create(:online_service_customer_relation, :monthly_payment, :stripe_subscribed, customer: customer) }
  let(:event) { StripeMock.mock_webhook_event('invoice.payment_failed', { subscription: relation.stripe_subscription_id }) }
  let(:args) do
    {
      event: event
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "creates a failed payment" do
      allow(Notifiers::Users::CustomerPayments::ChargeFailedToOwner).to receive(:run)
      allow(Notifiers::Customers::CustomerPayments::ChargeFailedToCustomer).to receive(:run)

      expect {
        outcome
      }.to change {
        customer.customer_payments.where(order_id: event.data.object.id).count
      }.by(1)

      expect(outcome.result).to have_attributes(
        amount_cents: event.data.object.total,
        amount_currency: customer.user.currency,
        order_id: event.data.object.id,
        state: "processor_failed"
      )

      expect(Notifiers::Users::CustomerPayments::ChargeFailedToOwner).to have_received(:run).with(
        receiver: customer.user,
        customer_payment: CustomerPayment.processor_failed.last
      )

      expect(Notifiers::Customers::CustomerPayments::ChargeFailedToCustomer).to have_received(:run).with(
        receiver: customer,
        customer_payment: CustomerPayment.processor_failed.last
      )
    end
  end
end

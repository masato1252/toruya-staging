# frozen_string_literal: true

require "rails_helper"

RSpec.describe StripeEvents::PaymentUpcoming do
  before { StripeMock.start }
  after { StripeMock.stop }
  let(:subscription) { FactoryBot.create(:subscription, :with_stripe) }
  let(:customer) { FactoryBot.create(:customer, user: subscription.user, with_stripe: true) }
  let(:relation) { FactoryBot.create(:online_service_customer_relation, :monthly_payment, :stripe_subscribed, customer: customer) }
  let(:event) { StripeMock.mock_webhook_event('invoice.invoice_upcoming', { subscription: relation.stripe_subscription_id }) }
  let(:args) do
    {
      event: event
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    xit "calls a charge reminder job" do
      allow(Notifiers::Customers::OnlineServices::ChargeReminder).to receive(:run)

      outcome

      expect(Notifiers::Customers::OnlineServices::ChargeReminder).to have_received(:run).with(
        receiver: customer,
        online_service_customer_relation: relation,
        online_service_customer_price: relation.price_details.first
      )
    end
  end
end

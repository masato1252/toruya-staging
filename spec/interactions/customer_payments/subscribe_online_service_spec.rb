# frozen_string_literal: true

require "rails_helper"

RSpec.describe CustomerPayments::SubscribeOnlineService do
  before { StripeMock.start }
  after { StripeMock.stop }
  let(:subscription) { FactoryBot.create(:subscription, :with_stripe) }
  let(:customer) { FactoryBot.create(:customer, user: subscription.user, with_stripe: true) }
  let(:social_customer) { FactoryBot.create(:social_customer, customer: customer) }
  let(:relation) { FactoryBot.create(:online_service_customer_relation, :monthly_payment, customer: customer) }
  let(:args) do
    {
      online_service_customer_relation: relation
    }
  end
  let(:outcome) { described_class.run(args) }

  context "when subscribes successfully" do
    before do
      # Mock successful Stripe subscription creation
      stripe_subscription = double(
        id: "sub_test_123",
        status: "active",
        latest_invoice: double(
          payment_intent: double(
            status: "succeeded",
            client_secret: "pi_test_secret"
          )
        )
      )
      allow(Stripe::Subscription).to receive(:create).and_return(stripe_subscription)
      allow(Stripe::Subscription).to receive(:retrieve).and_return(stripe_subscription)

      # Mock payment method retrieval for the Subscribe interaction
      allow_any_instance_of(OnlineServiceCustomerRelations::Subscribe).to receive(:get_selected_payment_method).and_return("pm_test_123")
    end

    it "changes to expected state" do
      allow(Sales::OnlineServices::SendLineCard).to receive(:run)
      outcome

      expect(relation).to be_paid_payment_state
      expect(relation).to be_active
    end

    context "when service is bundler" do
      let(:bundler_service) { FactoryBot.create(:online_service, :bundler, end_on_days: 365) }
      let!(:relation) { FactoryBot.create(:online_service_customer_relation, :monthly_payment, online_service: bundler_service, customer: customer) }

      it "changes to expected state" do
        outcome

        expect(relation).to be_paid_payment_state
        expect(relation).to be_active
      end
    end
  end

  context "when subscribes failed" do
    before do
      # Mock failed Stripe subscription creation
      stripe_subscription = double(
        id: "sub_test_failed",
        status: "incomplete",
        latest_invoice: double(
          payment_intent: double(
            status: "requires_payment_method",
            client_secret: "pi_test_failed_secret"
          )
        )
      )
      allow(Stripe::Subscription).to receive(:create).and_return(stripe_subscription)

      # Mock payment method retrieval for the Subscribe interaction
      allow_any_instance_of(OnlineServiceCustomerRelations::Subscribe).to receive(:get_selected_payment_method).and_return("pm_test_123")
    end

    it "changes to expected state" do
      outcome

      expect(relation).to be_failed_payment_state
      expect(relation).to be_pending
    end
  end
end

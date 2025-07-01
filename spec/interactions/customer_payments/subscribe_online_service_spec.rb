# frozen_string_literal: true

require "rails_helper"

RSpec.describe CustomerPayments::SubscribeOnlineService do
  before { StripeMock.start }
  after { StripeMock.stop }

  let(:subscription) { FactoryBot.create(:subscription, :with_stripe) }
  let(:customer) { FactoryBot.create(:customer, user: subscription.user, with_stripe: true) }
  let(:social_customer) { FactoryBot.create(:social_customer, customer: customer) }
  let(:relation) { FactoryBot.create(:online_service_customer_relation, :monthly_payment, customer: customer) }
  let(:args) { { online_service_customer_relation: relation } }
  let(:outcome) { described_class.run(args) }

  # Helper methods for cleaner mocks
  def mock_failed_subscription_outcome
    errors_mock = instance_double('ActiveInteraction::Errors',
      clear: nil,
      merge!: nil,
      empty?: false,
      full_messages: ['Subscription failed'],
      messages: {},
      details: {}
    )

    instance_double('ActiveInteraction::Outcome',
      valid?: false,
      errors: errors_mock
    )
  end

  def mock_successful_stripe_subscription
    stripe_subscription = double('Stripe::Subscription',
      id: "sub_test_123",
      status: "active",
      latest_invoice: double('Stripe::Invoice',
        payment_intent: double('Stripe::PaymentIntent',
          status: "succeeded",
          client_secret: "pi_test_secret"
        )
      )
    )

    allow(Stripe::Subscription).to receive(:create).and_return(stripe_subscription)
    allow(Stripe::Subscription).to receive(:retrieve).and_return(stripe_subscription)
    allow_any_instance_of(OnlineServiceCustomerRelations::Subscribe)
      .to receive(:get_selected_payment_method).and_return("pm_test_123")
  end

  def stub_failed_subscription
    allow(OnlineServiceCustomerRelations::Subscribe)
      .to receive(:run)
      .and_return(mock_failed_subscription_outcome)
  end

  context "when subscribes successfully" do
    before { mock_successful_stripe_subscription }

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
    before { stub_failed_subscription }

    it "changes to expected state" do
      outcome

      expect(relation).to be_failed_payment_state
      expect(relation).to be_pending
    end

    context "when relation is not in incomplete_payment_state" do
      before { relation.pending_payment_state! }

      it "sets relation to failed_payment_state when subscription fails" do
        expect(relation).to receive(:failed_payment_state!).and_call_original
        expect(relation).not_to be_incomplete_payment_state

        outcome

        expect(relation).to be_failed_payment_state
        expect(outcome.valid?).to be_truthy
      end
    end

    context "when relation is already in incomplete_payment_state" do
      before { relation.incomplete_payment_state! }

      it "does not change to failed_payment_state when subscription fails" do
        expect(relation).not_to receive(:failed_payment_state!)
        expect(relation).to be_incomplete_payment_state

        outcome

        expect(relation).to be_incomplete_payment_state
        expect(relation).not_to be_failed_payment_state
        expect(outcome.valid?).to be_truthy
      end
    end

    context "when testing the conditional logic explicitly" do
      context "when relation is in pending state (not incomplete)" do
        before { relation.pending_payment_state! }

        it "calls failed_payment_state! because relation is not in incomplete_payment_state" do
          expect(relation).to receive(:failed_payment_state!).and_call_original
          expect(relation).not_to be_incomplete_payment_state

          outcome
          expect(relation).to be_failed_payment_state
        end
      end

      context "when relation is in incomplete state" do
        before { relation.incomplete_payment_state! }

        it "does not call failed_payment_state! because relation is in incomplete_payment_state" do
          expect(relation).not_to receive(:failed_payment_state!)
          expect(relation).to be_incomplete_payment_state

          outcome
          expect(relation).to be_incomplete_payment_state
        end
      end
    end
  end
end

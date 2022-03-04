# frozen_string_literal: true

require "rails_helper"

# TODO: Fix
RSpec.describe OnlineServiceCustomerRelations::Unsubscribe do
  before { StripeMock.start }
  after { StripeMock.stop }
  let(:subscription) { FactoryBot.create(:subscription, :with_stripe) }
  let(:customer) { FactoryBot.create(:customer, user: subscription.user, with_stripe: true) }

  let(:args) do
    {
      relation: relation
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when relation was not available" do
      # expired relation
      let(:relation) { FactoryBot.create(:online_service_customer_relation, :monthly_payment, :stripe_subscribed, :expired, customer: customer, permission_state: :active) }

      context "when stripe_subscribed was still active" do
        it "cancels old stripe subscription" do
          old_stripe_subscription_id = relation.stripe_subscription_id

          outcome

          expect(Stripe::Subscription.retrieve(old_stripe_subscription_id).status).to eq(STRIPE_SUBSCRIPTION_STATUS[:canceled])
          expect(outcome.result.expire_at).to be_present
          expect(outcome.result).to be_canceled_payment_state
        end
      end

      context "when stripe_subscribed was canceled" do
        before do
          Stripe::Subscription.delete(relation.stripe_subscription_id)
        end

        it "does nothing" do
          outcome

          expect(outcome.result).to eq(relation)
        end
      end
    end

    context "when relation was available" do
      let(:relation) { FactoryBot.create(:online_service_customer_relation, :monthly_payment, :stripe_subscribed, customer: customer, permission_state: :active) }

      context "when stripe_subscribed was active" do
        it "cancels old stripe subscription" do
          old_stripe_subscription_id = relation.stripe_subscription_id

          outcome

          expect(Stripe::Subscription.retrieve(old_stripe_subscription_id).status).to eq(STRIPE_SUBSCRIPTION_STATUS[:canceled])
          expect(outcome.result.expire_at).to be_present
          expect(outcome.result).to be_canceled_payment_state
        end
      end

      context "when stripe_subscribed was canceled" do
        before do
          Stripe::Subscription.delete(relation.stripe_subscription_id)
        end

        it "cancels old stripe subscription" do
          old_stripe_subscription_id = relation.stripe_subscription_id

          outcome

          expect(Stripe::Subscription.retrieve(old_stripe_subscription_id).status).to eq(STRIPE_SUBSCRIPTION_STATUS[:canceled])
          expect(outcome.result.expire_at).to be_present
          expect(outcome.result).to be_canceled_payment_state
        end
      end
    end
  end
end

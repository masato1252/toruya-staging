# frozen_string_literal: true

require "rails_helper"

RSpec.describe CustomerPayments::SubscribeOnlineService do
  before { StripeMock.start }
  after { StripeMock.stop }
  let(:subscription) { FactoryBot.create(:subscription, :with_stripe) }
  let(:customer) { FactoryBot.create(:customer, user: subscription.user, with_stripe: true) }
  let(:relation) { FactoryBot.create(:online_service_customer_relation, :monthly_payment, customer: customer) }

  let(:args) do
    {
      online_service_customer_relation: relation
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "updates relation payment state to paid" do
      outcome

      expect(relation.stripe_subscription_id).to be_present
      expect(relation).to be_paid_payment_state
    end

    context "when relation was not available" do
      let(:relation) { FactoryBot.create(:online_service_customer_relation, :monthly_payment, :stripe_subscribed, :expired, customer: customer, permission_state: :active) }

      it "cancels old stripe subscription and create a new one" do
        old_stripe_subscription_id = relation.stripe_subscription_id

        expect {
          outcome
        }.to change {
          relation.stripe_subscription_id
        }

        expect(Stripe::Subscription.retrieve(old_stripe_subscription_id).status).to eq("canceled")
      end
    end

    context "when relation was available" do
      let(:relation) { FactoryBot.create(:online_service_customer_relation, :monthly_payment, customer: customer, permission_state: :active) }

      it "does nothing" do
        outcome

        expect(outcome.result).to eq(relation)
      end
    end
  end
end

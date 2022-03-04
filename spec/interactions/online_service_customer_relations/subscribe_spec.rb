# frozen_string_literal: true

require "rails_helper"

RSpec.describe OnlineServiceCustomerRelations::Subscribe do
  before { StripeMock.start }
  after { StripeMock.stop }
  let(:subscription) { FactoryBot.create(:subscription, :with_stripe) }
  let(:customer) { FactoryBot.create(:customer, user: subscription.user, with_stripe: true) }
  let(:relation) { FactoryBot.create(:online_service_customer_relation, :monthly_payment, customer: customer) }

  let(:args) do
    {
      relation: relation
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
      context "when its stripe subscription is still active" do
        let(:relation) { FactoryBot.create(:online_service_customer_relation, :stripe_subscribed, :monthly_payment, customer: customer, permission_state: :active) }

        it "does nothing" do
          expect {
            outcome
          }.not_to change {
            relation.stripe_subscription_id
          }
        end
      end

      context "when its stripe subscription is canceled" do
        let(:relation) { FactoryBot.create(:online_service_customer_relation, :stripe_subscribed, :monthly_payment, customer: customer, permission_state: :active) }
        before { Stripe::Subscription.delete(relation.stripe_subscription_id) }

        it "does nothing" do
          expect {
            outcome
          }.to change {
            relation.stripe_subscription_id
          }
        end
      end
    end
  end
end

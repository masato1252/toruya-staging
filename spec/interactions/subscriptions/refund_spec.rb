# frozen_string_literal: true

require "rails_helper"

RSpec.describe Subscriptions::Refund do
  before do
    StripeMock.start
    stripe_charge = Stripe::Charge.create({
      amount: subscription_charge.plan.cost(0),
      currency: user.currency,
      customer: stripe_customer_id,
    })
    subscription_charge.stripe_charge_details = stripe_charge.as_json
    subscription_charge.save!
  end
  after { StripeMock.stop }

  let(:subscription) { FactoryBot.create(:subscription, :with_stripe, :basic) }
  let!(:subscription_charge) { FactoryBot.create(:subscription_charge, :manual, :completed, user: user) }
  let(:user) { subscription.user }
  let(:stripe_customer_id) { subscription.stripe_customer_id }
  let(:args) do
    {
      user: user
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when the first manual charge is refunded" do
      let!(:subscription_charge) { FactoryBot.create(:subscription_charge, :manual, :refunded) }

      it "adds error" do
        expect(outcome.errors.details[:user]).to include(error: :subscription_is_not_refundable)
      end
    end

    context "when the first manual charge is over 8 day" do
      let!(:subscription_charge) { FactoryBot.create(:subscription_charge, :manual, created_at: 8.days.ago) }

      it "adds error" do
        expect(outcome.errors.details[:user]).to include(error: :subscription_is_not_refundable)
      end
    end

    it "refunds user and reset subscription" do
      outcome

      subscription_charge.reload
      subscription.reload
      stripe_charge = Stripe::Charge.retrieve(subscription_charge.stripe_charge_details["id"])

      expect(subscription_charge).to be_refunded
      expect(stripe_charge.amount_refunded).to eq(subscription_charge.amount_cents)
      expect(stripe_charge.refunded).to eq(true)
      expect(subscription).to be_active # we don't make it inactive immediately
      expect(subscription.expired_date).to eq(Subscription.today.yesterday)
      expect(subscription.next_plan).to be_nil
    end
  end
end

require "rails_helper"

RSpec.describe Subscriptions::Charge do
  let(:user) { FactoryBot.create(:user) }
  let(:plan) { Plan.premium_level.take }
  let(:stripe_helper) { StripeMock.create_test_helper }
  let(:stripe_customer) do
    Stripe::Customer.create({
      email: user.email,
      source: stripe_helper.generate_card_token
    })
  end
  let(:args) do
    {
      user: user,
      plan: plan,
      stripe_customer_id: stripe_customer.id,
      manual: true
    }
  end
  let(:outcome) { described_class.run(args) }
  before { StripeMock.start }
  after { StripeMock.stop }

  describe "#execute" do
    it "create a completed subscription charges record" do
      outcome

      charge = user.subscription_charges.where(
        plan: plan,
        amount_cents: plan.cost,
        amount_currency: Money.default_currency.to_s,
        charge_date: Subscription.today,
        manual: true
      ).last

      charge.reload
      expect(charge).to be_completed
      expect(charge.stripe_charge_details).to be_a(Hash)
      expect(charge.order_id).to be_present
    end

    context "when charges failed" do
      it "create a charge_failed subscription charges record" do
        StripeMock.prepare_card_error(:card_declined)

        outcome

        charge = user.subscription_charges.where(
          plan: plan,
          amount_cents: plan.cost,
          amount_currency: Money.default_currency.to_s,
          charge_date: Subscription.today,
          manual: true
        ).last

        expect(charge).to be_charge_failed
      end
    end
  end
end

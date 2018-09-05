require "rails_helper"

RSpec.describe Subscriptions::Charge do
  before { StripeMock.start }
  after { StripeMock.stop }
  let(:user) { FactoryBot.create(:user) }
  let(:plan) { Plan.premium_level.take }
  let!(:subscription) { FactoryBot.create(:subscription, user: user, stripe_customer_id: stripe_customer.id) }
  let(:stripe_helper) { StripeMock.create_test_helper }
  let(:stripe_customer) do
    Stripe::Customer.create({
      email: user.email,
      source: stripe_helper.generate_card_token
    })
  end
  let(:manual) { true }
  let(:args) do
    {
      user: user,
      plan: plan,
      manual: manual
    }
  end
  let(:outcome) { described_class.run(args) }

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

    context "when charge failed" do
      it "create a auth_failed subscription charges record" do
        StripeMock.prepare_card_error(:card_declined)

        outcome

        charge = user.subscription_charges.where(
          plan: plan,
          amount_cents: plan.cost,
          amount_currency: Money.default_currency.to_s,
          charge_date: Subscription.today,
          manual: true
        ).last

        expect(charge).to be_auth_failed
      end

      context "when charge is automatically" do
        let(:manual) { false }

        it "notfiy users" do
          StripeMock.prepare_card_error(:card_declined)
          expect(SubscriptionMailer).to receive(:charge_failed).and_return(double(deliver_now: true))

          outcome
        end
      end
    end
  end
end

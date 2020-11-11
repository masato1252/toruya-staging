require "rails_helper"

RSpec.describe Subscriptions::ResidualValue do
  let(:user) { subscription.user }
  let(:stripe_customer_id) { subscription.stripe_customer_id }
  let(:args) do
    {
      user: user
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when user is subscribing free plan" do
      let(:subscription) { FactoryBot.create(:subscription) }

      it "returns Money.zero" do
        expect(outcome.result).to eq(Money.zero)
      end
    end

    context "when user is subscribing paid plan" do
      let(:subscription) { FactoryBot.create(:subscription, :basic) }
      let!(:subscription_charge) { FactoryBot.create(:subscription_charge, :plan_subscruption, :manual, :completed, user: user) }

      it "returns expected amount" do
        expect(outcome.result).to eq(Money.new(2200) * Rational(1, 30))
      end
    end
  end
end

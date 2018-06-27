require "rails_helper"

RSpec.describe Subscriptions::ManualCharge do
  let(:subscription) { FactoryBot.create(:subscription) }
  let(:plan) { Plan.premium_level.take }
  let(:authorize_token) { SecureRandom.hex }
  let(:stripe_customer_id) do
    Stripe::Customer.create({
      email: subscription.user.email,
      source: StripeMock.create_test_helper.generate_card_token
    }).id
  end
  let(:args) do
    {
      subscription: subscription,
      plan: plan,
      authorize_token: authorize_token
    }
  end
  let(:outcome) { described_class.run(args) }

  before do
    Time.zone = "Tokyo"
    Timecop.freeze(Date.new(2018, 1, 31))
    StripeMock.start
  end
  after { StripeMock.stop }

  describe "#execute" do
    it "charges subscription" do
      allow(Payments::StoreStripeCustomer).to receive(:run).and_return(spy(valid?: true, result: stripe_customer_id))
      outcome

      subscription.reload
      expect(Payments::StoreStripeCustomer).to have_received(:run).with(user: subscription.user, authorize_token: authorize_token)
      expect(subscription.plan).to eq(plan)
      expect(subscription.next_plan).to be_nil
      expect(subscription.recurring_day).to eq(Subscription.today.day)
      expect(subscription.expired_date).to eq(Date.new(2018, 2, 28))
    end
  end
end

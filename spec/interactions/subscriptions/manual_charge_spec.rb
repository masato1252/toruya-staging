require "rails_helper"

RSpec.describe Subscriptions::ManualCharge do
  let(:user) { subscription.user }
  let(:subscription) { FactoryBot.create(:subscription, :with_stripe) }
  let(:plan) { Plan.premium_level.take }
  let(:authorize_token) { StripeMock.create_test_helper.generate_card_token }
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
    it "charges subscription and completed charge" do
      allow(SubscriptionMailer).to receive(:charge_successfully).with(subscription).and_return(double(deliver_now: true))
      outcome

      subscription.reload
      charge = subscription.user.subscription_charges.last
      expect(SubscriptionMailer).to have_received(:charge_successfully).with(subscription)
      expect(subscription.plan).to eq(plan)
      expect(subscription.next_plan).to be_nil
      expect(subscription.recurring_day).to eq(Subscription.today.day)
      expect(subscription.expired_date).to eq(Date.new(2018, 2, 28))
      expect(charge.expired_date).to eq(Date.new(2018, 2, 28))
      expect(charge).to be_completed
      fee = Plans::Fee.run!(user: user, plan: plan)
      expect(charge.details).to eq({
        "shop_ids" => user.shop_ids,
        "shop_fee" => fee.fractional,
        "shop_fee_format" => fee.format,
        "type" => SubscriptionCharge::TYPES[:plan_subscruption],
        "user_name" => user.name,
        "user_email" => user.email,
        "pure_plan_amount" => Plans::Price.run!(user: user, plan: plan).format,
        "plan_amount" => Plans::Price.run!(user: user, plan: plan, with_business_signup_fee: true).format,
        "plan_name" => plan.name
      })
    end

    context "when charge failed" do
      it "create a failed charge and doesn't change subscription" do
        StripeMock.prepare_card_error(:card_declined)

        expect(SubscriptionMailer).not_to receive(:charge_successfully)
        old_expired_date = subscription.expired_date

        expect(outcome).to be_invalid
        subscription.reload
        charge = subscription.user.subscription_charges.last

        expect(subscription.expired_date).to eq(old_expired_date)
        expect(charge).to be_auth_failed
      end
    end
  end
end

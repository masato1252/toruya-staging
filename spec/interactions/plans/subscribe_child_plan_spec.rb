require "rails_helper"

RSpec.describe Plans::SubscribeChildPlan do
  before do
    Time.zone = "Tokyo"
    Timecop.freeze(Date.new(2018, 1, 31))
    StripeMock.start
  end
  after { StripeMock.stop }

  let(:user) { subscription.user }
  let(:subscription) { FactoryBot.create(:subscription, :with_stripe) }
  let!(:referral) { factory.create_referral(referrer: user, state: :pending) }
  let(:plan) { Plan.child_basic_level.take }
  let(:authorize_token) { StripeMock.create_test_helper.generate_card_token }
  let(:args) do
    {
      user: user,
      plan: plan,
      authorize_token: authorize_token,
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "creates charge cost 19,800 yen annual plan fee and referee got 1,980 yen bonus" do
      allow(Notifiers::Subscriptions::ChargeSuccessfully).to receive(:run).with(receiver: subscription.user, user: subscription.user).and_return(double(deliver_now: true))
      expect(user.reference).to be_pending
      outcome

      subscription.reload
      charge = subscription.user.subscription_charges.find_by(amount_cents: 19_800, amount_currency: "JPY")
      expect(Notifiers::Subscriptions::ChargeSuccessfully).to have_received(:run).with(receiver: subscription.user, user: subscription.user)
      expect(subscription.plan).to eq(plan)
      expect(subscription.user.reload.member_plan).to eq(Plan::CHILD_BASIC_PLAN)
      expect(subscription.next_plan).to be_nil
      expect(subscription.recurring_day).to eq(Subscription.today.day)
      expect(subscription.expired_date).to eq(Date.new(2019, 1, 31))
      expect(charge.expired_date).to eq(Date.new(2019, 1, 31))
      expect(charge).to be_completed
      expect(charge.manual).to eq(true)
      expect(charge.amount).to eq(Money.new(19_800, :jpy))
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
        "plan_name" => plan.name,
        "charge_amount" => Money.new(19_800).format,
        "residual_value" => Money.zero.format
      })

      expect(user.reference.reload).to be_active

      payment = user.reference.referee.payments.last
      expect(payment.payment_withdrawal_id).to be_nil
      expect(payment.amount).to eq(Money.new(1_980, :jpy))
      expect(payment.referrer).to eq(user)
      expect(payment.details).to eq({
        "type" => Payment::TYPES[:referral_connect]
      })
    end

    context "when charges failed" do
      it "doesn't change referral state" do
        StripeMock.prepare_card_error(:card_declined)

        expect {
          outcome
        }.not_to change {
          user.reference.reload.state
        }
      end
    end
  end
end

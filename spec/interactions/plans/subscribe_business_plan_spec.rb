# frozen_string_literal: true

require "rails_helper"

RSpec.describe Plans::SubscribeBusinessPlan do
  before do
    Time.zone = "Tokyo"
    Timecop.freeze(Date.new(2018, 1, 31))
    StripeMock.start
  end
  after { StripeMock.stop }

  let(:subscription) { FactoryBot.create(:subscription, :with_stripe) }
  let(:plan) { Plan.business_level.take }
  let(:user) { subscription.user }
  let(:authorize_token) { StripeMock.create_test_helper.generate_card_token }
  let(:args) do
    {
      user: user,
      authorize_token: authorize_token,
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "creates charge cost 55,000 yen annual plan fee and 8,800 yen registration fee" do
      allow(Notifiers::Subscriptions::ChargeSuccessfully).to receive(:run).with(receiver: subscription.user, user: subscription.user).and_return(double(deliver_now: true))
      outcome

      subscription.reload
      charge = subscription.user.subscription_charges.find_by(amount_cents: 63_800, amount_currency: "JPY")
      expect(Notifiers::Subscriptions::ChargeSuccessfully).to have_received(:run).with(receiver: subscription.user, user: subscription.user)
      expect(subscription.plan).to eq(plan)
      expect(subscription.user.reload.member_plan).to eq(Plan::BUSINESS_PLAN)
      expect(subscription.next_plan).to be_nil
      expect(subscription.recurring_day).to eq(Subscription.today.day)
      expect(subscription.expired_date).to eq(Date.new(2019, 1, 31))
      expect(charge.expired_date).to eq(Date.new(2019, 1, 31))
      expect(charge).to be_completed
      expect(charge.manual).to eq(true)
      expect(charge.amount).to eq(Money.new(63_800, :jpy))
      fee = Plans::Fee.run!(user: user, plan: plan)
      expect(charge.details).to eq({
        "shop_ids" => user.shop_ids,
        "shop_fee" => fee.fractional,
        "shop_fee_format" => fee.format,
        "type" => SubscriptionCharge::TYPES[:business_member_sign_up],
        "user_name" => user.name,
        "user_email" => user.email,
        "pure_plan_amount" => Plans::Price.run!(user: user, plan: plan).format,
        "plan_amount" => Plans::Price.run!(user: user, plan: plan, with_business_signup_fee: true).format,
        "plan_name" => plan.name,
        "charge_amount" => Money.new(63_800).format,
        "residual_value" => Money.zero.format
      })

      expect(Notifiers::Subscriptions::ChargeSuccessfully).to have_received(:run)
    end

    context "when user is a referrer" do
      let(:subscription) { FactoryBot.create(:subscription, :child_basic, :with_stripe) }
      let(:referee) { FactoryBot.create(:user) }

      before { factory.create_referral(referee: referee, referrer: user, state: :active) }

      it "The referee gets 5,500 yen pending payment and referral was canceled" do
        allow(Notifiers::Subscriptions::ChargeSuccessfully).to receive(:run).with(receiver: subscription.user, user: subscription.user).and_return(double(deliver_now: true))
        outcome

        expect(subscription.user.reload).to be_business_member

        payment = referee.payments.last
        expect(payment.payment_withdrawal_id).to be_nil
        expect(payment.amount).to eq(Money.new(5_500, :jpy))
        expect(payment.referrer).to eq(user)
        expect(payment.details).to eq({
          "type" => Payment::TYPES[:referral_disconnect]
        })
        expect(user.reference).to be_referrer_canceled
        expect(Notifiers::Subscriptions::ChargeSuccessfully).to have_received(:run).with(receiver: subscription.user, user: subscription.user)
      end
    end
  end
end

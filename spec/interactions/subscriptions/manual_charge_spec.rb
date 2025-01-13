# frozen_string_literal: true

require "rails_helper"

RSpec.describe Subscriptions::ManualCharge do
  let(:user) { subscription.user }
  let(:subscription) { FactoryBot.create(:subscription, :with_stripe) }
  let(:plan) { Plan.basic_level.take }
  let(:rank) { 0 }
  let(:authorize_token) { StripeMock.create_test_helper.generate_card_token }
  let(:args) do
    {
      subscription: subscription,
      plan: plan,
      rank: rank,
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
      allow(Notifiers::Users::Subscriptions::ChargeSuccessfully).to receive(:run).with(receiver: subscription.user, user: subscription.user).and_return(double(deliver_now: true))
      outcome

      subscription.reload
      charge = subscription.user.subscription_charges.last
      expect(Notifiers::Users::Subscriptions::ChargeSuccessfully).to have_received(:run).with(receiver: subscription.user, user: subscription.user)
      expect(subscription.plan).to eq(plan)
      expect(subscription.next_plan).to be_nil
      expect(subscription.recurring_day).to eq(Subscription.today.day)
      expect(subscription.expired_date).to eq(Date.new(2018, 2, 28))
      expect(charge.expired_date).to eq(Date.new(2018, 2, 28))
      expect(charge).to be_completed
      fee = Plans::Fee.run!(user: user, plan: plan)
      expect(charge.details).to eq({
        "shop_ids" => user.shop_ids,
        "type" => SubscriptionCharge::TYPES[:plan_subscruption],
        "user_name" => user.name,
        "user_email" => user.email,
        "pure_plan_amount" => Plans::Price.run!(user: user, plan: plan)[0].format,
        "plan_amount" => Plans::Price.run!(user: user, plan: plan, with_business_signup_fee: true)[0].format,
        "plan_name" => plan.name,
        "charge_amount" => Plans::Price.run!(user: user, plan: plan, with_business_signup_fee: true)[0].format,
        "residual_value" => Money.zero.format,
        "rank" => rank
      })
    end

    context "when user choose a lower rank than they had" do
      let(:basic_customer_limit) { 2 }
      let(:basic_customer_max_limit) { 5 }
      before do
        stub_const("Plan::DETAILS_JP", {
          Plan::BASIC_LEVEL => [
            {
              rank: 0,
              max_customers_limit: basic_customer_limit,
              cost: 2_200,
            },
            {
              rank: 1,
              max_customers_limit: basic_customer_max_limit,
              cost: 3_000,
            },
            {
              rank: 2,
              max_customers_limit: Float::INFINITY
            },
          ]
        })
      end

      it "charges expected rank" do
        FactoryBot.create_list(:customer, basic_customer_limit + 1, user: user)

        outcome

        charge = subscription.user.subscription_charges.last

        expect(charge.rank).to eq(1)
        expect(subscription.rank).to eq(1)
      end
    end

    context "when user upgrade plan" do
      let(:subscription) { FactoryBot.create(:subscription, :with_stripe, :basic) }
      let!(:subscription_charge) { FactoryBot.create(:subscription_charge, :plan_subscruption, :manual, :completed, user: user) }
      let(:plan) { Plan.premium_level.take }

      it "charges expected amount" do
        outcome

        charge = subscription.user.subscription_charges.last
        residual_value = (Money.new(2200) * Rational(charge.expired_date - Subscription.today, charge.expired_date - charge.charge_date))

        expect(charge.amount).to eq(Plans::Price.run!(user: user, plan: plan)[0] - residual_value)
        fee = Plans::Fee.run!(user: user, plan: plan)
        expect(charge.details).to eq({
          "shop_ids" => user.shop_ids,
          "type" => SubscriptionCharge::TYPES[:plan_subscruption],
          "user_name" => user.name,
          "user_email" => user.email,
          "pure_plan_amount" => Plans::Price.run!(user: user, plan: plan)[0].format,
          "plan_amount" => Plans::Price.run!(user: user, plan: plan)[0].format,
          "plan_name" => plan.name,
          "charge_amount" => charge.amount.format,
          "residual_value" => residual_value.format,
          "rank" => rank
        })
      end
    end

    context "when user downgrade plan" do
      let(:subscription) { FactoryBot.create(:subscription, :with_stripe, :basic) }
      let(:plan) { Plan.free_level.take }

      it "is invalid" do
        expect(outcome).to be_invalid
      end
    end

    xcontext "when plan is business" do
      let(:plan) { Plan.business_level.take }

      it "charges subscription and completed charge with different details type and expired date" do
        allow(Notifiers::Users::Subscriptions::ChargeSuccessfully).to receive(:run).with(receiver: subscription.user, user: subscription.user).and_return(double(deliver_now: true))
        outcome

        subscription.reload
        charge = subscription.user.subscription_charges.last

        expect(subscription.plan).to eq(plan)
        expect(subscription.next_plan).to be_nil
        expect(subscription.recurring_day).to eq(Subscription.today.day)
        expect(subscription.expired_date).to eq(Date.new(2019, 1, 31))
        expect(charge.expired_date).to eq(Date.new(2019, 1, 31))
        expect(charge).to be_completed
        fee = Plans::Fee.run!(user: user, plan: plan)
        expect(charge.details).to eq({
          "shop_ids" => user.shop_ids,
          "shop_fee" => fee.fractional,
          "shop_fee_format" => fee.format,
          "type" => SubscriptionCharge::TYPES[:business_member_sign_up],
          "user_name" => user.name,
          "user_email" => user.email,
          "pure_plan_amount" => Plans::Price.run!(user: user, plan: plan)[0].format,
          "plan_amount" => Plans::Price.run!(user: user, plan: plan, with_business_signup_fee: true)[0].format,
          "plan_name" => plan.name,
          "charge_amount" => Plans::Price.run!(user: user, plan: plan, with_business_signup_fee: true)[0].format,
          "residual_value" => Money.zero.format
        })
      end
    end

    context "when charge failed" do
      it "create a failed charge and doesn't change subscription" do
        StripeMock.prepare_card_error(:card_declined)

        expect(Notifiers::Users::Subscriptions::ChargeSuccessfully).not_to receive(:run)
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

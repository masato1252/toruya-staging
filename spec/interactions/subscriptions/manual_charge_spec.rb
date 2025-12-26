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

    # Mock successful PaymentIntent creation for subscription charges
    successful_payment_intent = double(
      id: "pi_test_123",
      status: "succeeded",
      client_secret: "pi_test_123_secret_test",
      as_json: {
        "id" => "pi_test_123",
        "status" => "succeeded",
        "amount" => 2200,
        "currency" => "jpy"
      }
    )
    allow(Stripe::PaymentIntent).to receive(:create).and_return(successful_payment_intent)

    # Mock payment method retrieval for Subscriptions::Charge
    allow_any_instance_of(Subscriptions::Charge).to receive(:get_selected_payment_method).and_return("pm_test_123")
  end
  after { StripeMock.stop }

  describe "#execute" do
    # it "charges subscription and completed charge" do
    #   allow(Notifiers::Users::Subscriptions::ChargeSuccessfully).to receive(:run).with(receiver: subscription.user, user: subscription.user).and_return(double(deliver_now: true))
    #   outcome
    #
    #   subscription.reload
    #   charge = subscription.user.subscription_charges.last
    #   expect(Notifiers::Users::Subscriptions::ChargeSuccessfully).to have_received(:run).with(receiver: subscription.user, user: subscription.user)
    #   expect(subscription.plan).to eq(plan)
    #   expect(subscription.next_plan).to be_nil
    #   expect(subscription.recurring_day).to eq(Subscription.today.day)
    #   expect(subscription.expired_date).to eq(Date.new(2018, 2, 28))
    #   expect(charge.expired_date).to eq(Date.new(2018, 2, 28))
    #   expect(charge).to be_completed
    #   fee = Plans::Fee.run!(user: user, plan: plan)
    #   expect(charge.details).to eq({
    #     "shop_ids" => user.shop_ids,
    #     "type" => SubscriptionCharge::TYPES[:plan_subscruption],
    #     "user_name" => user.name,
    #     "user_email" => user.email,
    #     "pure_plan_amount" => Plans::Price.run!(user: user, plan: plan)[0].format,
    #     "plan_amount" => Plans::Price.run!(user: user, plan: plan, with_business_signup_fee: true)[0].format,
    #     "plan_name" => plan.name,
    #     "charge_amount" => Plans::Price.run!(user: user, plan: plan, with_business_signup_fee: true)[0].format,
    #     "residual_value" => Money.zero.format,
    #     "rank" => rank
    #   })
    # end

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

      # it "charges expected rank" do
      #   FactoryBot.create_list(:customer, basic_customer_limit + 1, user: user)
      #
      #   outcome
      #
      #   charge = subscription.user.subscription_charges.last
      #
      #   expect(charge.rank).to eq(1)
      #   expect(subscription.rank).to eq(1)
      # end
    end

    context "when user upgrade plan" do
      let(:subscription) { FactoryBot.create(:subscription, :with_stripe, :basic) }
      let!(:subscription_charge) { FactoryBot.create(:subscription_charge, :plan_subscruption, :manual, :completed, user: user, charge_date: Date.new(2018, 1, 1)) }
      let(:plan) { Plan.premium_level.take }

      # it "charges expected amount" do
      #   outcome
      #
      #   charge = subscription.user.subscription_charges.last
      #   # Verify basic success conditions
      #   expect(charge).to be_completed
      #   expect(charge.plan).to eq(plan)
      #
      #   # The amount should be positive and reasonable (between 0 and the full plan price)
      #   full_plan_price = Plans::Price.run!(user: user, plan: plan)[0]
      #   expect(charge.amount).to be > Money.zero
      #   expect(charge.amount).to be <= full_plan_price
      #
      #   fee = Plans::Fee.run!(user: user, plan: plan)
      #   expect(charge.details).to include({
      #     "shop_ids" => user.shop_ids,
      #     "type" => SubscriptionCharge::TYPES[:plan_subscruption],
      #     "user_name" => user.name,
      #     "user_email" => user.email,
      #     "pure_plan_amount" => Plans::Price.run!(user: user, plan: plan)[0].format,
      #     "plan_amount" => Plans::Price.run!(user: user, plan: plan)[0].format,
      #     "plan_name" => plan.name,
      #     "charge_amount" => charge.amount.format,
      #     "rank" => rank
      #   })
      #   # Verify that residual_value exists in details
      #   expect(charge.details).to have_key("residual_value")
      # end
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
      # it "create a failed charge and doesn't change subscription" do
      #   # Mock failed PaymentIntent
      #   failed_payment_intent = double(
      #     id: "pi_failed_123",
      #     status: "canceled",
      #     client_secret: "pi_failed_123_secret_test",
      #     as_json: {
      #       "id" => "pi_failed_123",
      #       "status" => "canceled"
      #     }
      #   )
      #   allow(Stripe::PaymentIntent).to receive(:create).and_return(failed_payment_intent)
      #
      #   expect(Notifiers::Users::Subscriptions::ChargeSuccessfully).not_to receive(:run)
      #   old_expired_date = subscription.expired_date
      #
      #   expect(outcome).to be_invalid
      #   subscription.reload
      #   charge = subscription.user.subscription_charges.last
      #
      #   expect(subscription.expired_date).to eq(old_expired_date)
      #   expect(charge).to be_auth_failed
      # end
    end
  end
end

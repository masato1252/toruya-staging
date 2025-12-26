# frozen_string_literal: true

require "rails_helper"

RSpec.describe Subscriptions::RecurringCharge do
  let(:subscription) { FactoryBot.create(:subscription) }
  let(:user) { subscription.user }
  let(:args) do
    {
      subscription: subscription
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when users change their plans" do
      let(:subscription) { FactoryBot.create(:subscription, :premium, next_plan: next_plan) }
      let(:next_plan) { Plan.free_level.take }

      it "changes subscription to next plan" do
        outcome

        subscription.reload
        expect(subscription.plan).to eq(next_plan)
        expect(subscription.next_plan).to be_nil
      end
    end

    context "when the plan is free" do
      it "charges nothing" do
        expect(Subscriptions::Charge).not_to receive(:run)

        outcome
      end
    end

    context "when the paid need to be charged" do
      before do
        Time.zone = "Tokyo"
        Timecop.freeze(Date.new(2018, 1, 31))
        StripeMock.start
      end
      after { StripeMock.stop }
      let(:subscription) { FactoryBot.create(:subscription, :premium, :with_stripe) }

      it "charges user" do
        # Mock successful payment intent for recurring charges
        successful_intent = double(
          status: "succeeded",
          as_json: {
            "id" => "pi_success_123",
            "status" => "succeeded",
            "amount" => 5500,
            "currency" => "jpy"
          }
        )
        allow(Stripe::PaymentIntent).to receive(:create).and_return(successful_intent)

        # Mock payment method retrieval for Charge interaction
        allow_any_instance_of(Subscriptions::Charge).to receive(:get_selected_payment_method).and_return("pm_test_123")

        allow(Notifiers::Users::Subscriptions::ChargeSuccessfully).to receive(:run).with(receiver: subscription.user, user: subscription.user).and_return(double(deliver_now: true))
        outcome

        subscription.reload
        charge = user.subscription_charges.last

        expect(subscription.plan).to eq(Plan.premium_level.take)
        expect(subscription.next_plan).to be_nil
        expect(subscription.expired_date).to eq(Date.new(2018, 2, 28))
        expect(subscription.user.subscription_charges.last.expired_date).to eq(Date.new(2018, 2, 28))
        expect(Notifiers::Users::Subscriptions::ChargeSuccessfully).to have_received(:run).with(receiver: subscription.user, user: subscription.user)

        plan = Plan.premium_level.take
        fee = Plans::Fee.run!(user: user, plan: plan)
        expect(charge.details).to eq({
          "shop_ids" => user.shop_ids,
          "shop_fee" => fee.fractional,
          "shop_fee_format" => fee.format,
          "type" => SubscriptionCharge::TYPES[:plan_subscruption],
          "user_name" => user.name,
          "user_email" => user.email,
          "plan_amount" => Plans::Price.run!(user: user, plan: plan)[0].format,
          "plan_name" => plan.name,
          "rank" => subscription.rank
        })
      end

      context "when charging users failed" do
        let(:subscription) { FactoryBot.create(:subscription, :basic, :with_stripe, next_plan: Plan.premium_level.take) }

        before do
          # Mock failed payment intent for recurring charges
          failed_intent = double(
            as_json: {
              "error" => { "message" => "Your card was declined." },
              "id" => "pi_failed_123",
              "status" => "payment_failed"
            },
            status: "payment_failed",
            id: "pi_failed_123",
            client_secret: "pi_failed_123_secret"
          )
          allow(Stripe::PaymentIntent).to receive(:create).and_return(failed_intent)

          # Mock payment method retrieval for Charge interaction
          allow_any_instance_of(Subscriptions::Charge).to receive(:get_selected_payment_method).and_return("pm_test_123")
        end

        # it "doesn't change subscription and create failed charge" do
        #   expect(Notifiers::Users::Subscriptions::ChargeSuccessfully).not_to receive(:run)
        #   expect(Notifiers::Users::Subscriptions::ChargeFailed).to receive(:run)
        #
        #   expect(outcome).to be_invalid
        #
        #   subscription.reload
        #   charge = subscription.user.subscription_charges.last
        #
        #   expect(subscription.plan).to eq(Plan.basic_level.take)
        #   expect(subscription.next_plan).to eq(Plan.premium_level.take)
        #   expect(subscription.expired_date).to eq(subscription.expired_date)
        #   expect(charge).to be_auth_failed
        # end
      end

      context "when user got more customers" do
        let(:subscription) { FactoryBot.create(:subscription, :basic, :with_stripe, rank: 0) }
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
                max_customers_limit: Float::INFINITY,
                cost: 4_000,
              },
            ]
          })

          # Mock successful payment intent for recurring charges
          successful_intent = double(
            status: "succeeded",
            as_json: {
              "id" => "pi_success_123",
              "status" => "succeeded",
              "amount" => 3000,
              "currency" => "jpy"
            }
          )
          allow(Stripe::PaymentIntent).to receive(:create).and_return(successful_intent)

          # Mock payment method retrieval for Charge interaction
          allow_any_instance_of(Subscriptions::Charge).to receive(:get_selected_payment_method).and_return("pm_test_123")
        end

        it "upgrades user's rank automatically" do
          FactoryBot.create_list(:customer, basic_customer_limit + 1, user: user)

          outcome

          subscription.reload
          charge = user.subscription_charges.last

          expect(subscription.plan).to eq(Plan.basic_level.take)
          expect(subscription.rank).to eq(1)
          expect(charge.rank).to eq(1)

          plan = Plan.basic_level.take
          fee = Plans::Fee.run!(user: user, plan: plan)
          expect(charge.details).to eq({
            "shop_ids" => user.shop_ids,
            "shop_fee" => fee.fractional,
            "shop_fee_format" => fee.format,
            "type" => SubscriptionCharge::TYPES[:plan_subscruption],
            "user_name" => user.name,
            "user_email" => user.email,
            "plan_amount" => Plans::Price.run!(user: user, plan: plan)[0].format,
            "plan_name" => plan.name,
            "rank" => subscription.rank
          })
        end
      end
    end

    context "when user is an enabled referrer" do
      before do
        Time.zone = "Tokyo"
        Timecop.freeze(Date.new(2018, 1, 31))
        StripeMock.start
      end

      after { StripeMock.stop }
      let!(:referral) { FactoryBot.create(:referral, referrer: user) }
      let(:subscription) { FactoryBot.create(:subscription, :child_basic, :with_stripe, next_plan: next_plan) }

      context "when referee was still busienss member" do
        context "when next plan is a child plan" do
          let(:next_plan) { Plan.child_premium_level.take }

          xit "changes subscription to next plan" do
            allow(Notifiers::Users::Subscriptions::ChargeSuccessfully).to receive(:run).with(receiver: subscription.user, user: subscription.user).and_return(double(deliver_now: true))

            outcome

            subscription.reload
            expect(subscription.plan).to eq(next_plan)
            expect(subscription.next_plan).to be_nil
            expect(referral.reload).to be_active

            charge = subscription.user.subscription_charges.find_by(amount_cents: 49_500, amount_currency: "JPY")
            expect(subscription.plan).to eq(next_plan)
            expect(subscription.user.reload.member_plan).to eq(Plan::CHILD_PREMIUM_PLAN)
            expect(subscription.next_plan).to be_nil
            expect(subscription.recurring_day).to eq(Subscription.today.day)
            expect(subscription.expired_date).to eq(Date.new(2019, 1, 31))
            expect(charge.expired_date).to eq(Date.new(2019, 1, 31))
            expect(charge).to be_completed
            expect(charge.manual).to eq(false)
            expect(charge.amount).to eq(Money.new(49_500, :jpy))
            fee = Plans::Fee.run!(user: user, plan: next_plan)
            expect(charge.details).to eq({
              "shop_ids" => user.shop_ids,
              "shop_fee" => fee.fractional,
              "shop_fee_format" => fee.format,
              "type" => SubscriptionCharge::TYPES[:plan_subscruption],
              "user_name" => user.name,
              "user_email" => user.email,
              "plan_amount" => Plans::Price.run!(user: user, plan: next_plan)[0].format,
              "plan_name" => next_plan.name,
              "rank" => subscription.rank
            })

            payment = user.reference.referee.payments.last
            expect(payment.payment_withdrawal_id).to be_nil
            expect(payment.amount).to eq(Money.new(4_950, :jpy))
            expect(payment.referrer).to eq(user)
            expect(payment.details).to eq({
              "type" => Payment::TYPES[:referral_connect]
            })

            expect(Notifiers::Users::Subscriptions::ChargeSuccessfully).to have_received(:run).with(receiver: subscription.user, user: subscription.user)
          end
        end

        context "when next plan is a free plan" do
          let(:next_plan) { Plan.free_level.take }

          it "changes subscription to next plan" do
            outcome

            subscription.reload
            expect(subscription.plan).to eq(next_plan)
            expect(subscription.next_plan).to be_nil
            expect(referral.reload).to be_referrer_canceled
            expect(referral.referrer.subscription_charges).to be_empty
            expect(referral.referee.payments).to be_empty
          end
        end

        xcontext "when next plan is a busienss plan" do
          let(:next_plan) { Plan.business_level.take }

          it "changes subscription to next plan" do
            allow(Notifiers::Users::Subscriptions::ChargeSuccessfully).to receive(:run).with(receiver: subscription.user, user: subscription.user).and_return(double(deliver_now: true))

            outcome

            subscription.reload
            expect(subscription.plan).to eq(next_plan)
            expect(subscription.next_plan).to be_nil

            charge = subscription.user.subscription_charges.find_by(amount_cents: 55_000, amount_currency: "JPY")
            expect(subscription.plan).to eq(next_plan)
            expect(subscription.user.reload.member_plan).to eq(Plan::BUSINESS_PLAN)
            expect(subscription.next_plan).to be_nil
            expect(subscription.recurring_day).to eq(Subscription.today.day)
            expect(subscription.expired_date).to eq(Date.new(2019, 1, 31))
            expect(charge.expired_date).to eq(Date.new(2019, 1, 31))
            expect(charge).to be_completed
            expect(charge.manual).to eq(false)
            expect(charge.amount).to eq(Money.new(55_000, :jpy))
            fee = Plans::Fee.run!(user: user, plan: next_plan)
            expect(charge.details).to eq({
              "shop_ids" => user.shop_ids,
              "shop_fee" => fee.fractional,
              "shop_fee_format" => fee.format,
              "type" => SubscriptionCharge::TYPES[:plan_subscruption],
              "user_name" => user.name,
              "user_email" => user.email,
              "plan_amount" => Plans::Price.run!(user: user, plan: next_plan)[0].format,
              "plan_name" => next_plan.name,
              "rank" => subscription.rank
            })

            payment = referral.referee.payments.last
            expect(payment.payment_withdrawal_id).to be_nil
            expect(payment.amount).to eq(Money.new(5_500, :jpy))
            expect(payment.referrer).to eq(user)
            expect(payment.details).to eq({
              "type" => Payment::TYPES[:referral_disconnect]
            })
            expect(referral.reload).to be_referrer_canceled

            expect(Notifiers::Users::Subscriptions::ChargeSuccessfully).to have_received(:run).with(receiver: subscription.user, user: subscription.user)
          end
        end
      end
    end
  end
end

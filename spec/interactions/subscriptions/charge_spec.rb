# frozen_string_literal: true

require "rails_helper"

RSpec.describe Subscriptions::Charge do
  before { StripeMock.start }
  after { StripeMock.stop }

  let(:plan) { Plan.premium_level.take }
  let(:user) { subscription.user }
  let!(:subscription) { FactoryBot.create(:subscription, :with_stripe) }
  let(:manual) { true }
  let(:rank) { 0 }
  let(:args) do
    {
      user: user,
      plan: plan,
      rank: rank,
      manual: manual
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when payment succeeds" do
      before do
        # Mock successful PaymentIntent
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

        # Mock payment method retrieval
        allow_any_instance_of(described_class).to receive(:get_selected_payment_method).and_return("pm_test_123")
      end

      it "create a completed subscription charges record" do
        outcome

        charge = user.subscription_charges.where(
          plan: plan,
          amount_cents: plan.cost(rank),
          amount_currency: Money.default_currency.to_s,
          charge_date: Subscription.today,
          manual: true
        ).last

        charge.reload
        expect(charge).to be_completed
        expect(charge.stripe_charge_details).to be_a(Hash)
        expect(charge.order_id).to be_present
      end
    end

    context "when charge failed" do
      let(:failed_intent) do
        double(
          as_json: {
            "error" => { "message" => "Your card was declined." },
            "id" => "pi_failed_123",
            "status" => "canceled"
          },
          status: "canceled",
          id: "pi_failed_123",
          client_secret: "pi_failed_123_secret"
        )
      end

      before do
        allow(Stripe::PaymentIntent).to receive(:create).and_return(failed_intent)
        # Mock payment method retrieval
        allow_any_instance_of(described_class).to receive(:get_selected_payment_method).and_return("pm_test_123")
      end

      it "create a auth_failed subscription charges record" do
        outcome

        charge = user.subscription_charges.where(
          plan: plan,
          manual: true
        ).order(created_at: :desc).first

        expect(charge).to be_present
        expect(charge).to be_auth_failed
        expect(charge.stripe_charge_details).to be_a(Hash)
      end

      context "when charge is automatically" do
        let(:manual) { false }
        let(:failed_intent) do
          double(
            as_json: {
              "error" => { "message" => "Your card was declined." },
              "id" => "pi_failed_123",
              "status" => "payment_failed"
            },
            status: "payment_failed",
            id: "pi_failed_123",
            client_secret: "pi_failed_123_secret"
          )
        end
        before do
          user.update(phone_number: nil)
        end

        it "notfiy users" do
          expect(Notifiers::Users::Subscriptions::ChargeFailed).to receive(:run).with(
            receiver: user,
            user: user,
            subscription_charge: kind_of(SubscriptionCharge)
          ).and_call_original

          outcome
        end
      end
    end
  end
end

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

    context "when user is a referrer and charge completed" do
      let(:referral) { factory.create_referral }
      let(:user) { referral.referrer }

      it "calls Referrals::ReferrerCharged" do
        allow(Referrals::ReferrerCharged).to receive(:run).and_call_original

        outcome

        expect(Referrals::ReferrerCharged).to have_received(:run).with(referral: referral, charge: outcome.result, plan: plan)
      end

      context "when referee is not under business plan"  do
        let(:referral) { factory.create_referral(referee: FactoryBot.create(:subscription, plan: Plan.premium_level.take).user) }

        it "does NOT call Referrals::ReferrerCharged" do
          outcome

          expect(Referrals::ReferrerCharged).not_to receive(:run)
        end
      end

      context "when referral is not active"  do
        let(:referral) { factory.create_referral(state: :referrer_canceled) }

        it "does NOT call Referrals::ReferrerCharged" do
          outcome

          expect(Referrals::ReferrerCharged).not_to receive(:run)
        end
      end

      context "when charge is not completed"  do
        let(:charge) { FactoryBot.create(:subscription_charge, :refunded, user: referral.referrer, plan: Plan.business_level.take) }

        it "does NOT call Referrals::ReferrerCharged" do
          outcome

          expect(Referrals::ReferrerCharged).not_to receive(:run)
        end
      end

      context "when referrer is not under child plan"  do
        let(:referral) { factory.create_referral(referrer: FactoryBot.create(:subscription, plan: Plan.basic_level.take).user) }

        it "does NOT call Referrals::ReferrerCharged" do
          outcome

          expect(Referrals::ReferrerCharged).not_to receive(:run)
        end
      end
    end

    context "when charge failed" do
      it "create a auth_failed subscription charges record" do
        StripeMock.prepare_card_error(:card_declined)

        outcome

        charge = user.subscription_charges.where(
          plan: plan,
          amount_cents: plan.cost(rank),
          amount_currency: Money.default_currency.to_s,
          charge_date: Subscription.today,
          manual: true
        ).last

        expect(charge).to be_auth_failed
      end

      context "when charge is automatically" do
        let(:manual) { false }
        before { user.update(phone_number: nil) }

        it "notfiy users" do
          StripeMock.prepare_card_error(:card_declined)
          expect(Notifiers::Users::Subscriptions::ChargeFailed).to receive(:run).and_call_original

          mailer_double = double(deliver_now: true)
          expect(UserMailer).to receive(:with).with(
            hash_including(
              email: anything,
              message: anything,
              subject: I18n.t("user_mailer.custom.title")
            )
          ).and_return(double(custom: mailer_double))

          outcome
        end
      end
    end
  end
end

require "rails_helper"

RSpec.describe Referrals::ReferrerCharged do
  let(:referral) { factory.create_referral }
  let(:user) { referral.referrer }
  let(:plan) { Plan.child_premium_level.take }
  let(:charge) { FactoryBot.create(:subscription_charge, :completed, user: user) }
  let(:args) do
    {
      referral: referral,
      plan: plan,
      charge: charge,
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when user is a referrer under child plan, its referee is under business plan and charge completed" do
      it "calls Payments::ReferralFee" do
        allow(Payments::ReferralFee).to receive(:run).and_call_original

        outcome

        expect(Payments::ReferralFee).to have_received(:run).with(referral: referral, charge: charge)
      end

      context "when referee is not under business plan"  do
        let(:referral) { factory.create_referral(referee: FactoryBot.create(:subscription, plan: Plan.premium_level.take).user) }

        it "does NOT call Payments::ReferralFee" do
          outcome

          expect(Payments::ReferralFee).not_to receive(:run)
        end
      end

      context "when referral is not active"  do
        let(:referral) { factory.create_referral(state: :referrer_canceled) }

        it "does NOT call Payments::ReferralFee" do
          outcome

          expect(Payments::ReferralFee).not_to receive(:run)
        end
      end

      context "when charge is not completed"  do
        let(:charge) { FactoryBot.create(:subscription_charge, :refunded, user: referral.referrer, plan: Plan.business_level.take) }

        it "does NOT call Payments::ReferralFee" do
          outcome

          expect(Payments::ReferralFee).not_to receive(:run)
        end
      end

      context "when referrer is not under child plan"  do
        let(:referral) { factory.create_referral(referrer: FactoryBot.create(:subscription, plan: Plan.basic_level.take).user) }

        it "does NOT call Payments::ReferralFee" do
          outcome

          expect(Payments::ReferralFee).not_to receive(:run)
        end
      end
    end

    context "when next plan is a busienss plan" do
      let(:plan) { Plan.business_level.take }

      it "calls expected behaviors" do
        allow(Payments::ReferralDisconnectFee).to receive(:run).and_call_original
        allow(Referrals::ReferrerCancel).to receive(:run).and_call_original

        outcome

        expect(Payments::ReferralDisconnectFee).to have_received(:run).with(referral: referral, charge: charge)
        expect(Referrals::ReferrerCancel).to have_received(:run).with(referral: referral)
      end
    end
  end
end

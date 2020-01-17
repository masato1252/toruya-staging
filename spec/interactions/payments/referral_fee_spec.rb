require "rails_helper"

RSpec.describe Payments::ReferralFee do
  let(:referral) { factory.create_referral }
  let(:charge) { FactoryBot.create(:subscription_charge, :completed, user: referral.referrer, plan: Plan.business_level.take) }

  let(:args) do
    {
      referral: referral,
      charge: charge,
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "The referee gets 5,500 yen pending payment" do
      outcome

      referee = referral.referee
      payment = referee.payments.last
      expect(payment.payment_withdrawal_id).to be_nil
      expect(payment.amount).to eq(charge.amount * Payments::ReferralFee::BONUS_FEE_RATIO)
      expect(payment.referrer).to eq(referral.referrer)
      expect(payment.details).to eq({
        "type" => Payment::TYPES[:referral_connect]
      })
    end

    context "when referee is not under business plan"  do
      let(:referral) { factory.create_referral(referee: FactoryBot.create(:subscription, plan: Plan.premium_level.take).user) }

      it "is invalid" do
        expect(outcome).to be_invalid
        expect(outcome.errors.details[:referral]).to eq([error: :invalid_referee_plan])
      end
    end

    context "when referral is not active"  do
      let(:referral) { factory.create_referral(state: :referrer_canceled) }

      it "is invalid" do
        expect(outcome).to be_invalid
        expect(outcome.errors.details[:referral]).to eq([error: :invalid_referral_state])
      end
    end

    context "when charge is not completed"  do
      let(:charge) { FactoryBot.create(:subscription_charge, :refunded, user: referral.referrer, plan: Plan.business_level.take) }

      it "is invalid" do
        expect(outcome).to be_invalid
        expect(outcome.errors.details[:charge]).to eq([error: :invalid_state])
      end
    end
  end
end

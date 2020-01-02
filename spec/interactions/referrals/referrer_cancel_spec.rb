require "rails_helper"

RSpec.describe Referrals::ReferrerCancel do
  let(:referral) { factory.create_referral(referrer: FactoryBot.create(:subscription, plan: Plan.basic_level.take).user) }
  let(:args) do
    {
      referral: referral
    }
  end

  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "cancels the referral" do
      outcome

      expect(referral.reload).to be_referrer_canceled
    end
  end
end

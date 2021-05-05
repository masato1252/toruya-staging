# frozen_string_literal: true

require "rails_helper"

RSpec.describe Subscriptions::Bonus do
  before { StripeMock.start }
  after { StripeMock.stop }

  let(:subscription) { FactoryBot.create(:subscription, :with_stripe) }
  let(:plan) {}
  let(:rank) {}
  let(:expired_date) { subscription.expired_date.next_month }
  let(:reason) { "foo" }
  let(:args) do
    {
      subscription: subscription,
      plan: plan,
      rank: rank,
      expired_date: expired_date,
      reason: reason
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "updates expected values" do
      outcome

      expect(subscription.expired_date).to eq(expired_date)
      expect(subscription.recurring_day).to eq(expired_date.day)
    end

    context "when expired_date is before subscription" do
      let(:expired_date) { subscription.expired_date.prev_month }

      it "is invalid" do
        expect(outcome).to be_invalid
      end
    end
  end
end

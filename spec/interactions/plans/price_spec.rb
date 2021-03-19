# frozen_string_literal: true

require "rails_helper"

RSpec.describe Plans::Price do
  let(:subscription) { FactoryBot.create(:subscription, :free) }
  let(:user) { subscription.user }
  let(:plan) { Plan.free_level.take }
  let(:args) do
    {
      user: user,
      plan: plan,
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when plan is child basic plan" do
      let(:plan) { Plan.child_basic_level.take }

      context "when it is first time charge" do
        it "returns 19,800 yen" do
          expect(outcome.result).to eq(Money.new(Plan.cost(Plan::CHILD_BASIC_PLAN).first, :jpy))
        end
      end

      context "when it is NOT first time charge" do
        before { FactoryBot.create(:subscription_charge, :completed, plan: plan, user: user) }

        it "returns 22,000 yen" do
          expect(outcome.result).to eq(Money.new(Plan.cost(Plan::CHILD_BASIC_PLAN).second, :jpy))
        end
      end
    end

    context "when plan is child premium plan" do
      let(:plan) { Plan.child_premium_level.take }

      context "when it is first time charge" do
        it "returns 49,500 yen" do
          expect(outcome.result).to eq(Money.new(Plan.cost(Plan::CHILD_PREMIUM_PLAN).first, :jpy))
        end
      end

      context "when it is NOT first time charge" do
        before { FactoryBot.create(:subscription_charge, :completed, plan: plan, user: user) }

        it "returns 55,000 yen" do
          expect(outcome.result).to eq(Money.new(Plan.cost(Plan::CHILD_PREMIUM_PLAN).second, :jpy))
        end
      end
    end
  end
end

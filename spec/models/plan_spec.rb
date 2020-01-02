require "rails_helper"

RSpec.describe Plan do
  describe ".cost_with_currency" do
    it "returns expected cost" do
      expect(Plan.cost_with_currency(Plan::BASIC_PLAN)).to eq(Money.new(2_200, :jpy))

      expect(Plan.cost_with_currency(Plan::CHILD_BASIC_PLAN)).to eq([
        Money.new(19_800, :jpy),
        Money.new(22_000, :jpy),
      ])
    end
  end

  describe "#become" do
    [
      { current_plan: Plan.free_level.take, new_plan: Plan.basic_level.take, result: :upgrade? },
      { current_plan: Plan.child_premium_level.take, new_plan: Plan.business_level.take, result: :same_grade? },
      { current_plan: Plan.child_premium_level.take, new_plan: Plan.child_basic_level.take, result: :downgrade? },
    ].each do |h|
      it "#{h[:current_plan].level} become #{h[:new_plan].level} #{h[:result]} is true" do
        expect(h[:current_plan].public_send(h[:result], h[:new_plan])).to eq(true)
      end
    end
  end
end

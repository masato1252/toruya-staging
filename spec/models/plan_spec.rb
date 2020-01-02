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
      { current_plan_level: :free_level,          new_plan_level: :basic_level,       result: :upgrade? },
      { current_plan_level: :child_premium_level, new_plan_level: :business_level,    result: :same_grade? },
      { current_plan_level: :child_premium_level, new_plan_level: :child_basic_level, result: :downgrade? },
    ].each do |h|
      let(:plan) {  }
      it "#{h[:current_plan_level]} become #{h[:new_plan_level]} #{h[:result]} is true" do
        current_plan = Plan.public_send(h[:current_plan_level]).take
        new_plan = Plan.public_send(h[:new_plan_level]).take

        expect(current_plan.public_send(h[:result], new_plan)).to eq(true)
      end
    end
  end
end

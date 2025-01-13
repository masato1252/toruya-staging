# frozen_string_literal: true

require "rails_helper"

RSpec.describe Plan do
  describe ".rank" do
    context "when plan is free" do
      context "when customers is 49" do
        it "returns rank 0" do
          expect(Plan.rank(Plan::FREE_LEVEL, 49)).to eq(0)
        end
      end

      context "when customers is 50" do
        it "returns rank 0" do
          expect(Plan.rank(Plan::FREE_LEVEL, 50)).to eq(0)
        end
      end

      context "when customers is 51" do
        it "returns rank 1" do
          expect(Plan.rank(Plan::FREE_LEVEL, 51)).to eq(1)
        end
      end
    end

    context "when plan is basic" do
      context "when customers is 199" do
        it "returns rank 1" do
          expect(Plan.rank(Plan::BASIC_LEVEL, 199)).to eq(1)
        end
      end

      context "when customers is 200" do
        it "returns rank 1" do
          expect(Plan.rank(Plan::BASIC_LEVEL, 200)).to eq(1)
        end
      end

      context "when customers is 201" do
        it "returns rank 2" do
          expect(Plan.rank(Plan::BASIC_LEVEL, 201)).to eq(2)
        end
      end

      context "when customers is 499" do
        it "returns rank 3" do
          expect(Plan.rank(Plan::BASIC_LEVEL, 499)).to eq(3)
        end
      end

      context "when customers is 500" do
        it "returns rank 3" do
          expect(Plan.rank(Plan::BASIC_LEVEL, 500)).to eq(3)
        end
      end

      context "when customers is 501" do
        it "returns rank 4" do
          expect(Plan.rank(Plan::BASIC_LEVEL, 501)).to eq(4)
        end
      end
    end
  end

  describe ".max_customers_limit" do
    context "when plan is free" do
      context "when rank is 0" do
        it "returns expected max_customers_limit" do
          expect(Plan.max_customers_limit(Plan::FREE_LEVEL, 0)).to eq(50)
        end
      end
    end

    context "when plan is basic" do
      context "when rank is 0" do
        it "returns expected max_customers_limit" do
          expect(Plan.max_customers_limit(Plan::BASIC_LEVEL, 0)).to eq(100)
        end
      end

      context "when rank is 1" do
        it "returns expected max_customers_limit" do
          expect(Plan.max_customers_limit(Plan::BASIC_LEVEL, 1)).to eq(200)
        end
      end

      context "when rank is 2" do
        it "returns expected max_customers_limit" do
          expect(Plan.max_customers_limit(Plan::BASIC_LEVEL, 2)).to eq(300)
        end
      end

      context "when rank is 3" do
        it "returns expected max_customers_limit" do
          expect(Plan.max_customers_limit(Plan::BASIC_LEVEL, 3)).to eq(500)
        end
      end

      context "when rank is 7" do
        it "returns expected max_customers_limit" do
          expect(Plan.max_customers_limit(Plan::BASIC_LEVEL, 7)).to eq(2000)
        end
      end
    end
  end

  describe ".cost_with_currency" do
    it "returns expected cost" do
      expect(Plan.cost_with_currency(Plan::BASIC_PLAN, 0)).to eq(Money.new(2_200, :jpy))
    end

    context "when plan is basic" do
      context "when rank is 0" do
        it "returns expected cost" do
          expect(Plan.cost_with_currency(Plan::BASIC_LEVEL, 0)).to eq(2_200.to_money)
        end
      end

      context "when rank is 7" do
        it "returns expected cost" do
          expect(Plan.cost_with_currency(Plan::BASIC_LEVEL, 7)).to eq(11_660.to_money)
        end
      end
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

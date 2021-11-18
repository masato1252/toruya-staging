# frozen_string_literal: true

# == Schema Information
#
# Table name: plans
#
#  id       :bigint           not null, primary key
#  level    :integer
#  position :integer
#

# level is kind of plan key, it doesn't mean permission level
class Plan < ApplicationRecord
  FREE_PLAN = FREE_LEVEL = DEFAULT_PLAN = "free".freeze
  TRIAL_PLAN = TRIAL_LEVEL = "trial".freeze
  BASIC_PLAN =  BASIC_LEVEL = "basic".freeze
  PREMIUM_PLAN = PREMIUM_LEVEL = "premium".freeze

  BUSINESS_PLAN = "business".freeze
  CHILD_BASIC_PLAN = "child_basic".freeze
  CHILD_PREMIUM_PLAN = "child_premium".freeze
  TRIAL_PLAN_THRESHOLD_DAYS = 30

  ANNUAL_CHARGE_PLANS = [BUSINESS_PLAN, CHILD_BASIC_PLAN, CHILD_PREMIUM_PLAN].freeze
  CHILD_PLANS = [CHILD_BASIC_PLAN, CHILD_PREMIUM_PLAN].freeze
  REGULAR_PLANS = [FREE_PLAN, BASIC_PLAN, PREMIUM_PLAN].freeze

  enum level: {
    free: 0,
    basic: 1,
    premium: 2,
    business: 3,
    child_basic: 4,
    child_premium: 5,
  }, _suffix: true

  DETAILS = {
    Plan::FREE_LEVEL => [
      {
        rank: 0,
        max_customers_limit: 50,
        max_sale_pages_limit: 3,
        cost: 0
      },
      {
        rank: 1,
        max_customers_limit: 100,
        max_sale_pages_limit: 3,
        cost: 0
      },
      {
        rank: 2,
        max_customers_limit: Float::INFINITY,
      }
    ],
    Plan::BASIC_LEVEL => [
      {
        rank: 0,
        max_customers_limit: 200,
        cost: 2_200,
      },
      {
        rank: 1,
        max_customers_limit: 300,
        cost: 2_750,
      },
      {
        rank: 2,
        max_customers_limit: 500,
        cost: 3_300
      },
      {
        rank: 3,
        max_customers_limit: 800,
        cost: 4_400
      },
      {
        rank: 4,
        max_customers_limit: 1000,
        cost: 4_950
      },
      {
        rank: 5,
        max_customers_limit: 1500,
        cost: 6_600
      },
      {
        rank: 6,
        max_customers_limit: 2000,
        cost: 8_250
      },
      {
        rank: 7,
        max_customers_limit: Float::INFINITY,
        cost: 8_250
      }
    ],
    Plan::PREMIUM_LEVEL => [
      {
        rank: 0,
        max_customers_limit: 200,
        cost: 5_500,
      },
      {
        rank: 1,
        max_customers_limit: 300,
        cost: 6_270,
      },
      {
        rank: 2,
        max_customers_limit: 500,
        cost: 7_040
      },
      {
        rank: 3,
        max_customers_limit: 800,
        cost: 8_580
      },
      {
        rank: 4,
        max_customers_limit: 1000,
        cost: 9_350
      },
      {
        rank: 5,
        max_customers_limit: 1500,
        cost: 11_660
      },
      {
        rank: 6,
        max_customers_limit: 2000,
        cost: 13_970
      },
      {
        rank: 7,
        max_customers_limit: Float::INFINITY,
        cost: 13_970
      }
    ]
  }.freeze

  def self.max_legal_rank
    Plan::DETAILS[Plan::BASIC_LEVEL].max{ |a, b| a[:rank] <=> b[:rank] }[:rank] - 1 #6
  end

  def self.rank(plan_level, customers_count)
    DETAILS[plan_level].each do |context|
      if customers_count <= context[:max_customers_limit]
        return context[:rank]
      end
    end
  end

  def self.max_customers_limit(plan_level, rank)
    plan_details(plan_level, rank)[:max_customers_limit]
  end

  def self.max_sale_pages_limit(plan_level, rank)
    plan_details(plan_level, rank)[:max_sale_pages_limit]
  end

  def self.plan_details(plan_level, rank)
    DETAILS[plan_level].find { |context| context[:rank] == rank } || DETAILS[plan_level].find { |context| context[:rank] == 0 }
  end

  def self.cost(plan_level, _rank)
    @@costs ||= {}
    @@costs["#{plan_level}-#{_rank}"] ||= plan_details(plan_level, _rank)[:cost]
  end

  def self.cost_with_currency(plan_level, _rank)
    @@cost_with_currency ||= {}
    @@cost_with_currency["#{plan_level}-#{_rank}"] ||= Money.new(cost(plan_level, _rank), Money.default_currency.id)
  end

  def cost(_rank)
    self.class.cost(level, _rank)
  end

  def cost_with_currency(_rank)
    self.class.cost_with_currency(level, _rank)
  end

  def name
    I18n.t("plan.level.#{level}")
  end

  def is_child?
    CHILD_PLANS.include?(level)
  end

  def self.permission_level(level)
    case level
    when FREE_PLAN
      FREE_LEVEL
    when BASIC_PLAN, CHILD_BASIC_PLAN
      BASIC_LEVEL
    when PREMIUM_PLAN, BUSINESS_PLAN, CHILD_PREMIUM_PLAN
      PREMIUM_LEVEL
    when TRIAL_PLAN
      TRIAL_LEVEL
    end
  end

  # -1: downgrade
  #  0: same level
  #  1: upgrade
  def become(plan)
    Plan.levels[self.class.permission_level(plan.level)] <=> Plan.levels[self.class.permission_level(level)]
  end

  def downgrade?(plan)
    become(plan).negative?
  end

  def upgrade?(plan)
    become(plan).positive?
  end

  def same_grade?(plan)
    become(plan).zero?
  end
end

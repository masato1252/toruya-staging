# frozen_string_literal: true

# == Schema Information
#
# Table name: plans
#
#  id       :bigint(8)        not null, primary key
#  position :integer
#  level    :integer
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
  REGULAR_PLANS = [FREE_PLAN, BASIC_PLAN].freeze

  enum level: {
    free: 0,
    basic: 1,
    premium: 2,
    business: 3,
    child_basic: 4,
    child_premium: 5,
  }, _suffix: true

  # COST = {
  #   jpy: {
  #     "free" => 0,
  #     "basic" => 2_200,
  #     "premium" => 5_500,
  #   },
  # }.freeze

  # ANNUAL_COST = {
  #   jpy: {
  #     "business" => 55_000,
  #     "child_basic" => [19_800, 22_000],
  #     "child_premium" => [49_500, 55_000],
  #   }
  # }.freeze

  DETAILS = {
    Plan::FREE_LEVEL => [
      {
        rank: 0,
        max_customers_limit: 50,
        max_sale_pages_limit: 3,
        cost: 0
      },
      {
        rank: 0,
        max_customers_limit: Float::INFINITY,
      }
    ],
    Plan::BASIC_LEVEL => [
      {
        rank: 0,
        max_customers_limit: 200,
        cost: 2_500,
      },
      {
        rank: 1,
        max_customers_limit: 300,
        cost: 3_000,
      },
      {
        rank: 2,
        max_customers_limit: 400,
        cost: 3_500
      },
      {
        rank: 3,
        max_customers_limit: 500,
        cost: 4_000
      },
      {
        rank: 4,
        max_customers_limit: 1000,
        cost: 5_000
      },
      {
        rank: 5,
        max_customers_limit: Float::INFINITY
      }
    ]
  }.freeze

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

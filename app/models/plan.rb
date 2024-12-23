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
  ENTERPRISE_PLAN = ENTERPRISE_LEVEL = "enterprise".freeze

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
    enterprise: 6
  }, _suffix: true

  DETAILS_OLD = {
    Plan::FREE_LEVEL => [
      { rank: 0, max_customers_limit: 50, max_sale_pages_limit: 3, cost: 0 },
      { rank: 1, max_customers_limit: 100, max_sale_pages_limit: 3, cost: 0 },
    ],
    Plan::BASIC_LEVEL => [
      { rank: 0, max_customers_limit: 200, cost: 2_200, },
      { rank: 1, max_customers_limit: 300, cost: 2_750, },
      { rank: 2, max_customers_limit: 500, cost: 3_300, },
      { rank: 3, max_customers_limit: 800, cost: 4_400, },
      { rank: 4, max_customers_limit: 1000, cost: 4_950, },
      { rank: 5, max_customers_limit: 1500, cost: 6_600, },
      { rank: 6, max_customers_limit: 2000, cost: 8_250, },
      { rank: 7, max_customers_limit: Float::INFINITY, cost: 8_250, },
    ],
    Plan::PREMIUM_LEVEL => [
      { rank: 0, max_customers_limit: 200, cost: 5_500, },
      { rank: 1, max_customers_limit: 300, cost: 6_270, },
      { rank: 2, max_customers_limit: 500, cost: 7_040, },
      { rank: 3, max_customers_limit: 800, cost: 8_580, },
      { rank: 4, max_customers_limit: 1000, cost: 9_350, },
      { rank: 5, max_customers_limit: 1500, cost: 11_660, },
      { rank: 6, max_customers_limit: 2000, cost: 13_970, },
      { rank: 7, max_customers_limit: Float::INFINITY, cost: 13_970, },
    ],
    Plan::ENTERPRISE_LEVEL => [
      { rank: 0, max_customers_limit: 200, cost: 5_500, },
      { rank: 1, max_customers_limit: 300, cost: 6_270, },
      { rank: 2, max_customers_limit: 500, cost: 7_040, },
      { rank: 3, max_customers_limit: 800, cost: 8_580, },
      { rank: 4, max_customers_limit: 1000, cost: 9_350, },
      { rank: 5, max_customers_limit: 1500, cost: 11_660, },
      { rank: 6, max_customers_limit: 2000, cost: 13_970, },
      { rank: 7, max_customers_limit: Float::INFINITY, cost: 13_970, },
    ]
  }.freeze

  DETAILS_JP = {
    Plan::FREE_LEVEL => [
      { rank: 0, max_customers_limit: 50, max_sale_pages_limit: 3, cost: 0 },
      { rank: 1, max_customers_limit: 100, max_sale_pages_limit: 3, cost: 0 },
    ],
    Plan::BASIC_LEVEL => [
      { rank: 0, max_customers_limit: 100, cost: 2_200, },
      { rank: 1, max_customers_limit: 200, cost: 2_750, },
      { rank: 2, max_customers_limit: 300, cost: 3_300, },
      { rank: 3, max_customers_limit: 500, cost: 4_950, },
      { rank: 4, max_customers_limit: 800, cost: 6_600, },
      { rank: 5, max_customers_limit: 1000, cost: 7_450, },
      { rank: 6, max_customers_limit: 1500, cost: 9_350, },
      { rank: 7, max_customers_limit: 2000, cost: 11_660, },
      { rank: 7, max_customers_limit: Float::INFINITY, cost: 11_660, },
    ],
    Plan::PREMIUM_LEVEL => [
      { rank: 0, max_customers_limit: 100, cost: 5_500, },
      { rank: 1, max_customers_limit: 200, cost: 5_500, },
      { rank: 2, max_customers_limit: 300, cost: 6_270, },
      { rank: 3, max_customers_limit: 500, cost: 7_040, },
      { rank: 4, max_customers_limit: 800, cost: 8_580, },
      { rank: 5, max_customers_limit: 1000, cost: 9_350, },
      { rank: 6, max_customers_limit: 1500, cost: 11_660, },
      { rank: 7, max_customers_limit: 2000, cost: 13_970, },
      { rank: 7, max_customers_limit: Float::INFINITY, cost: 13_970, },
    ],
    Plan::ENTERPRISE_LEVEL => [
      { rank: 0, max_customers_limit: 200, cost: 5_500, },
      { rank: 1, max_customers_limit: 300, cost: 6_270, },
      { rank: 2, max_customers_limit: 500, cost: 7_040, },
      { rank: 3, max_customers_limit: 800, cost: 8_580, },
      { rank: 4, max_customers_limit: 1000, cost: 9_350, },
      { rank: 5, max_customers_limit: 1500, cost: 11_660, },
      { rank: 6, max_customers_limit: 2000, cost: 13_970, },
      { rank: 7, max_customers_limit: Float::INFINITY, cost: 13_970, },
    ]
  }.freeze

  DETAILS_TW = {
    Plan::FREE_LEVEL => [
      { rank: 0, max_customers_limit: 50, max_sale_pages_limit: 3, cost: 0 },
      { rank: 1, max_customers_limit: 100, max_sale_pages_limit: 3, cost: 0 },
    ],
    Plan::BASIC_LEVEL => [
      { rank: 0, max_customers_limit: 100, cost: 300, },
      { rank: 1, max_customers_limit: 200, cost: 500, },
      { rank: 2, max_customers_limit: 300, cost: 800, },
      { rank: 3, max_customers_limit: 500, cost: 1_300, },
      { rank: 4, max_customers_limit: 800, cost: 2_100, },
      { rank: 5, max_customers_limit: 1000, cost: 2_500, },
      { rank: 6, max_customers_limit: 1500, cost: 3_300, },
      { rank: 7, max_customers_limit: 2000, cost: 4_100, },
      { rank: 7, max_customers_limit: Float::INFINITY, cost: 4_100, },
    ],
    Plan::PREMIUM_LEVEL => [
      { rank: 0, max_customers_limit: 100, cost: 500, },
      { rank: 1, max_customers_limit: 200, cost: 800, },
      { rank: 2, max_customers_limit: 300, cost: 1_300, },
      { rank: 3, max_customers_limit: 500, cost: 2_100, },
      { rank: 4, max_customers_limit: 800, cost: 3_300, },
      { rank: 5, max_customers_limit: 1000, cost: 3_900, },
      { rank: 6, max_customers_limit: 1500, cost: 4_900, },
      { rank: 7, max_customers_limit: 2000, cost: 6_100, },
      { rank: 7, max_customers_limit: Float::INFINITY, cost: 6_100, },
    ],
    Plan::ENTERPRISE_LEVEL => [
      { rank: 0, max_customers_limit: 200, cost: 500, },
      { rank: 1, max_customers_limit: 300, cost: 800, },
      { rank: 2, max_customers_limit: 500, cost: 1_300, },
      { rank: 3, max_customers_limit: 800, cost: 2_100, },
      { rank: 4, max_customers_limit: 1000, cost: 3_300, },
      { rank: 5, max_customers_limit: 1500, cost: 3_900, },
      { rank: 6, max_customers_limit: 2000, cost: 4_900, },
      { rank: 7, max_customers_limit: Float::INFINITY, cost: 4_900, },
    ]
  }.freeze

  def self.plans
    case I18n.locale
    when :tw
      DETAILS_TW
    else
      Date.today >= Date.parse("2025-01-10") ? DETAILS_JP : DETAILS_OLD
    end
  end

  def self.max_legal_rank
    plans[Plan::BASIC_LEVEL].max{ |a, b| a[:rank] <=> b[:rank] }[:rank] - 1 #7
  end

  def self.rank(plan_level, customers_count)
    plans[plan_level].each do |context|
      if customers_count <= context[:max_customers_limit]
        return context[:rank]
      end
    end
  end

  def self.max_customers_limit(plan_level, rank)
    plans[plan_level][rank][:max_customers_limit]
  end

  def self.max_sale_pages_limit(plan_level, rank)
    plans[plan_level][rank][:max_sale_pages_limit]
  end

  def self.plan_details(plan_level, rank)
    plans[plan_level].find { |context| context[:rank] == rank } || plans[plan_level].find { |context| context[:rank] == 0 }
  end

  def self.cost(plan_level, _rank)
    @@costs ||= {}
    @@costs["#{I18n.locale}_#{plan_level}-#{_rank}"] ||= plan_details(plan_level, _rank)[:cost]
  end

  def self.cost_with_currency(plan_level, _rank)
    @@cost_with_currency ||= {}
    @@cost_with_currency["#{I18n.locale}_#{plan_level}-#{_rank}"] ||= Money.new(cost(plan_level, _rank), User.currency)
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
    when ENTERPRISE_PLAN
      ENTERPRISE_LEVEL
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

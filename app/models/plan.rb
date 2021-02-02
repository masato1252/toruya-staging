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
  TRIAL_PLAN_THRESHOLD_MONTHS = 1

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

  COST = {
    jpy: {
      "free" => 0,
      "basic" => 2_200,
      "premium" => 5_500,
    },
  }.freeze

  ANNUAL_COST = {
    jpy: {
      "business" => 55_000,
      "child_basic" => [19_800, 22_000],
      "child_premium" => [49_500, 55_000],
    }
  }.freeze

  def self.cost(plan_level)
    @@costs ||= Hash.new do |h, key|
      h[key] = COST[Money.default_currency.id][key]
      h[key] ||= ANNUAL_COST[Money.default_currency.id][key]
    end

    @@costs[plan_level.to_s]
  end

  def self.cost_with_currency(plan_level)
    @@cost_with_currency ||= Hash.new do |h, key|
      h[key] =
        if cost(key).is_a?(Array)
          cost(key).map do |price|
            Money.new(price, Money.default_currency.id)
          end
        else
          Money.new(cost(key), Money.default_currency.id)
        end
    end

    @@cost_with_currency[plan_level.to_s]
  end

  def cost
    self.class.cost(level)
  end

  def cost_with_currency
    self.class.cost_with_currency(level)
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

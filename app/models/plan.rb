# == Schema Information
#
# Table name: plans
#
#  id       :bigint(8)        not null, primary key
#  position :integer
#  level    :integer
#

class Plan < ApplicationRecord
  FREE_LEVEL = DEFAULT_PLAN = "free".freeze
  TRIAL_LEVEL = "trial".freeze
  BASIC_LEVEL = "basic".freeze
  PREMIUM_LEVEL = "premium".freeze
  TRIAL_PLAN_THRESHOLD_MONTHS = 3

  enum level: {
    free: 0,
    basic: 1,
    premium: 2
  }, _suffix: true

  COST = {
    jpy: {
      "free" => 0,
      "basic" => 2_200,
      "premium" => 5_500,
    },
  }.freeze

  def self.cost(plan_level)
    @costs ||= Hash.new do |h, key|
      h[key] = COST[Money.default_currency.id][key]
    end

    @costs[plan_level.to_s]
  end

  def self.cost_with_currency(plan_level)
    @cost_with_currency ||= Hash.new do |h, key|
      h[key] = Money.new(cost(key), Money.default_currency.id)
    end

    @cost_with_currency[plan_level.to_s]
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

  # -1: downgrade
  #  0: same level
  #  1: upgrade
  def become(plan)
    Plan.levels[plan.level] <=> Plan.levels[level]
  end
end

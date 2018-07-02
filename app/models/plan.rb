# == Schema Information
#
# Table name: plans
#
#  id       :integer          not null, primary key
#  position :integer
#  level    :integer
#

class Plan < ApplicationRecord
  enum level: {
    free: 0,
    basic: 1,
    premium: 2
  }, _suffix: true

  COST = {
    jpy: {
      "free" => 0,
      "basic" => 2_160,
      "premium" => 5_400,
    },
  }.freeze

  def cost
    COST[Money.default_currency.id][level]
  end

  def cost_with_currency
    Money.new(cost, Money.default_currency.id)
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

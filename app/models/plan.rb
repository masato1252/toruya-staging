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

  # -1: upgrade
  #  0: same level
  #  1: downgrade
  def become(plan)
    Plan.levels[level] <=> Plan.levels[plan.level]
  end
end

# frozen_string_literal: true

class SubscriptionData < ActiveRecord::Migration[5.1]
  def change
    # https://github.com/ilake/kasaike/pull/360
    User.find_each do |user|
      Staffs::CreateOwner.run!(user: user) if user.profile
    end

    User.find_each do |user|
      user.create_subscription(plan: Plan.free_level.take) unless user.subscription
    end
  end
end

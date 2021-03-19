# frozen_string_literal: true

class MigrateChargeInfoToDetails < ActiveRecord::Migration[5.1]
  def change
    SubscriptionCharge.find_each do |charge|
      next unless charge.details

      charge.details =
        if charge.shop_fee?
          charge.details.merge!(
            user_name: charge.user&.name,
            user_email: charge.user&.email
          )
        else
          charge.details.merge!(
            user_name: charge.user&.name,
            user_email: charge.user&.email,
            plan_name: charge.plan.name,
            plan_amount: charge.plan.cost_with_currency.format,
          )
        end

      charge.save!
    end
  end
end

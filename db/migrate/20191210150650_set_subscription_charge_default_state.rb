# frozen_string_literal: true

class SetSubscriptionChargeDefaultState < ActiveRecord::Migration[5.2]
  def change
    change_column :subscription_charges, :state, :integer, default: 0, null: false
  end
end

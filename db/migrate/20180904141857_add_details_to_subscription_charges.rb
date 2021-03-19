# frozen_string_literal: true

class AddDetailsToSubscriptionCharges < ActiveRecord::Migration[5.1]
  def change
    add_column :subscription_charges, :details, :jsonb
  end
end

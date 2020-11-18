class AddDetailsTypeIndexToSubscriptionCharges < ActiveRecord::Migration[5.2]
  def change
    execute <<-SQL
      CREATE INDEX subscription_charge_type_index ON subscription_charges ((details->>'type'))
    SQL
  end
end

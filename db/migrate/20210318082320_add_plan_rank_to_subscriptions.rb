class AddPlanRankToSubscriptions < ActiveRecord::Migration[5.2]
  def change
    add_column :subscriptions, :rank, :integer, default: 0
    add_column :subscription_charges, :rank, :integer, default: 0
  end
end

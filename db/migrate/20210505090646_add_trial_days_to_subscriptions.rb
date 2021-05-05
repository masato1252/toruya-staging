class AddTrialDaysToSubscriptions < ActiveRecord::Migration[5.2]
  def change
    add_column :subscriptions, :trial_days, :integer, null: true
  end
end

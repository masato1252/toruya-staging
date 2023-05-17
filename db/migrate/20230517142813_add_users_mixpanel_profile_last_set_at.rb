class AddUsersMixpanelProfileLastSetAt < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :mixpanel_profile_last_set_at, :datetime
    add_column :customers, :mixpanel_profile_last_set_at, :datetime
  end
end

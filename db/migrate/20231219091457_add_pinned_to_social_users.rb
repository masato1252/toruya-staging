class AddPinnedToSocialUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :social_users, :pinned, :boolean, default: false, null: false
    add_index :social_users, [:pinned, :updated_at]
  end
end

class AddConsultantAtSocialUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :social_users, :consultant_at, :datetime
    add_index :social_users, :consultant_at
  end
end

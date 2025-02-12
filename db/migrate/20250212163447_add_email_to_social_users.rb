class AddEmailToSocialUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :social_users, :email, :string
    add_index :social_users, :email
  end
end

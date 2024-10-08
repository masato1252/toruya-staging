class AddLocaleToSocialUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :social_users, :locale, :string, default: 'ja'
    add_column :social_customers, :locale, :string, default: 'ja'
  end
end

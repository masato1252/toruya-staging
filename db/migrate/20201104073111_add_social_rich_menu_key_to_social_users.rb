class AddSocialRichMenuKeyToSocialUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :social_users, :social_rich_menu_key, :string
    add_index :social_users, :social_rich_menu_key
    add_column :social_customers, :social_rich_menu_key, :string
    add_index :social_customers, :social_rich_menu_key

    SocialUser.where.not(user_id: nil).find_each do |social_user|
      RichMenus::Connect.run(social_target: social_user, social_rich_menu: SocialRichMenu.find_by(social_name: "user_dashboard"))
    end

    SocialCustomer.where.not(customer_id: nil).find_each do |social_user|
      RichMenus::Connect.run(social_target: social_user, social_rich_menu: SocialRichMenu.find_by(social_name: "customer_reservations"))
    end
  end
end

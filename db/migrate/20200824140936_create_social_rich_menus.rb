class CreateSocialRichMenus < ActiveRecord::Migration[5.2]
  def change
    create_table :social_rich_menus do |t|
      t.integer :social_account_id
      t.string :social_rich_menu_id
      t.string :social_name
    end

    add_index :social_rich_menus, [:social_account_id, :social_name]
  end
end

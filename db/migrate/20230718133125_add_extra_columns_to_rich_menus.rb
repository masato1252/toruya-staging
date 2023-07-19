class AddExtraColumnsToRichMenus < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      add_column :social_rich_menus, :body, :jsonb
      add_column :social_rich_menus, :current, :boolean
      add_column :social_rich_menus, :default, :boolean
      add_column :social_rich_menus, :start_at, :datetime
      add_column :social_rich_menus, :end_at, :datetime

      add_index :social_rich_menus, [:social_account_id, :current], name: :current_rich_menu, unique: true
      add_index :social_rich_menus, [:social_account_id, :default], name: :default_rich_menu, unique: true

      SocialRichMenu.where.not(social_account_id: nil).update_all(default: true, current: true)
    end
  end
end

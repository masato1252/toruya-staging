class AddInternalNameToSocialRichMenus < ActiveRecord::Migration[7.0]
  def change
    add_column :social_rich_menus, :internal_name, :string
    add_column :social_rich_menus, :bar_label, :string
  end
end

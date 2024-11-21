class AddLocaleToSocialRichMenus < ActiveRecord::Migration[7.0]
  def change
    add_column :social_rich_menus, :locale, :string, null: false, default: 'ja'
    SocialRichMenu.update_all(locale: 'ja')
  end
end

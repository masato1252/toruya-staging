class AddTimestampToSocialRichMenus < ActiveRecord::Migration[7.0]
  def up
    add_timestamps(:social_rich_menus, null: false, default: -> { 'NOW()' })
  end

  def down
    remove_timestamps(:social_rich_menus)
  end
end

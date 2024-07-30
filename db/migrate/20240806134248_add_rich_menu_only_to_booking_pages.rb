class AddRichMenuOnlyToBookingPages < ActiveRecord::Migration[7.0]
  def change
    add_column :booking_pages, :rich_menu_only, :boolean, default: false
    add_index :booking_pages, :rich_menu_only
  end
end

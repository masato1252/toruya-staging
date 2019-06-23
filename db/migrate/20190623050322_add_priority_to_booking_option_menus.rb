class AddPriorityToBookingOptionMenus < ActiveRecord::Migration[5.2]
  def change
    add_column :booking_option_menus, :priority, :integer

    BookingOption.all.find_all do |option|
      option.booking_option_menus.each.with_index do |booking_option_menu, index|
        booking_option_menu.update_columns(priority: index)
      end
    end
  end
end

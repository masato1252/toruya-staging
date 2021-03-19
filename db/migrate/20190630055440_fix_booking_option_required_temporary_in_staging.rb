# frozen_string_literal: true

class FixBookingOptionRequiredTemporaryInStaging < ActiveRecord::Migration[5.2]
  def change
    # add_column :booking_option_menus, :required_time, :integer
    BookingOption.all.find_all do |option|
      option.booking_option_menus.each.with_index do |booking_option_menu, index|
        booking_option_menu.update_columns(priority: index, required_time: booking_option_menu.menu.minutes)
      end
      option.update_columns(minutes: option.booking_option_menus.sum(:required_time))
    end
  end
end

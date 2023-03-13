# frozen_string_literal: true

module Menus
  class Delete < ActiveInteraction::Base
    object :menu

    def execute
      menu.with_lock do
        menu.update_columns(deleted_at: Time.current)
        MenuCategory.where(menu_id: menu.id).destroy_all

        menu.booking_options.each do |booking_option|
          compose(BookingOptions::Delete, booking_option: booking_option)
        end
      end
    end
  end
end

# frozen_string_literal: true

# XXX: filter out the booking_options that contains some menus doesn't belongs_to the shop

module BookingPages
  class AvailableBookingOptions < ActiveInteraction::Base
    object :shop
    object :booking_page, default: nil

    def execute
      options = user.booking_options.includes(:menu_relations)

      if booking_page.present?
        options = options - booking_page.booking_options.includes(:menu_relations)
      end
      menu_ids = shop.shop_menus.pluck(:menu_id)

      options.find_all do |option|
        option_menu_ids = option.menu_relations.pluck(:menu_id)
        (option_menu_ids - menu_ids).empty?
      end
    end

    private

    def user
      shop.user
    end
  end
end

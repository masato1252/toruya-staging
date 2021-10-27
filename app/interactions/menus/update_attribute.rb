# frozen_string_literal: true

module Menus
  class UpdateAttribute < ActiveInteraction::Base
    object :menu
    string :update_attribute

    hash :attrs, default: nil do
      string :name, default: nil
      string :short_name, default: nil
      integer :minutes, default: nil
      integer :interval, default: nil
      array :menu_shops, default: nil
      boolean :online, default: nil
    end

    validate :validate_menu_usage

    def execute
      # TODO: Update all booking option updated_at

      menu.with_lock do
        case update_attribute
        when "name"
          menu.update(name: attrs[:name], short_name: attrs[:short_name])
        when "minutes", "interval", "online"
          menu.update(attrs.slice(update_attribute))
        when "menu_shops"
          menu.transaction do
            menu.shop_menus.destroy_all
            checked_menu_shops = attrs[:menu_shops].select{ |attribute| attribute["checked"].present? }
            new_shop_attrs = checked_menu_shops.map do |attr|
              { shop_id: attr[:shop_id], max_seat_number: attr[:max_seat_number].presence || 1 }
            end
            menu.shop_menus.create(new_shop_attrs)

            # XXX: If this menu was responsible by one staff(or no need manpower), then for sure, all the staffs had capability to handle it.
            if menu.min_staffs_number <= 1
              menu.staff_menus.update_all(max_customers: checked_menu_shops.map { |attr| attr[:max_seat_number].presence || "1" }.max)
            end
          end
        end

        if menu.errors.present?
          errors.merge!(menu.errors)
        else
          # XXX: Update the cache key that used in Booking::Calendar
          BookingOption.where(id: BookingOptionMenu.where(menu: menu.id).pluck(:booking_option_id)).update_all(updated_at: Time.current)
        end
      end

      menu
    end

    private

    def validate_menu_usage
      if update_attribute == "menu_shops" && menu.booking_option_menus.exists?
        checked_menu_shops = attrs[:menu_shops].select{ |attribute| attribute["checked"].present? }

        checked_shop_ids = checked_menu_shops.map {|attr| attr[:shop_id] }
        unchecked_shop_ids =  menu.user.shop_ids - checked_shop_ids

        booking_page_ids = BookingPageOption.where(booking_option_id: menu.booking_option_menus.pluck(:booking_option_id)).pluck(:booking_page_id)
        still_be_used_shop_ids = BookingPage.where(id: booking_page_ids).pluck(:shop_id)

        if (unchecked_shop_ids & still_be_used_shop_ids).present?
          errors.add(:menu, :be_used_by_booking_page)
        end
      end
    end
  end
end

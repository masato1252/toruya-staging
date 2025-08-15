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
      integer :min_staffs_number, default: nil
      array :menu_shops, default: nil
      array :menu_staffs, default: nil
      boolean :online, default: nil
    end

    validate :validate_menu_usage

    def execute
      menu.with_lock do
        case update_attribute
        when "name"
          menu.update(name: attrs[:name], short_name: attrs[:short_name])
        when "minutes"
          menu.update(attrs.slice(update_attribute))
          # Find all the booking_pages that use this menu, and update the minutes when booking option menu's required time is less than the new minutes
          # and this booking option only has one menu
          booking_option_ids = menu.booking_option_menus.pluck(:booking_option_id)
          BookingOptionMenu
            .where(booking_option_id: booking_option_ids, menu_id: menu.id)
            .update_all(required_time: attrs[:minutes])

          BookingOption.where(id: booking_option_ids).each do |booking_option|
            booking_option.update!(minutes: booking_option.booking_option_menus.sum(:required_time))
          end
        when "interval", "online", "min_staffs_number"
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
              menu.staff_menus.update_all(max_customers: checked_menu_shops.map { |attr| attr[:max_seat_number].presence || "1" }.map(&:to_i).max)
            end
          end
        when "menu_staffs"
          menu.transaction do
            menu.menu_staffs.destroy_all
            checked_menu_staffs = attrs[:menu_staffs].select{ |attribute| attribute["checked"].present? }
            new_staff_attrs = checked_menu_staffs.map do |attr|
              { staff_id: attr[:staff_id], max_customers: attr[:max_customers].presence || 1 }
            end

            menu.menu_staffs.create(new_staff_attrs)
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

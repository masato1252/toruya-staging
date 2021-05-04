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
    end

    def execute
      # TODO: Update all booking option updated_at

      menu.with_lock do
        case update_attribute
        when "name"
          menu.update(name: attrs[:name], short_name: attrs[:short_name])
        when "minutes", "interval"
          menu.update(attrs.slice(update_attribute))
        when "menu_shops"
          menu.transaction do
            menu.shop_menus.destroy_all
            checked_menu_shops = attrs[:menu_shops].select{ |attribute| attribute["checked"].present? }
            new_shop_attrs = checked_menu_shops.map do |attr|
              { shop_id: attr[:shop_id], max_seat_number: attr[:max_seat_number] }
            end
            menu.shop_menus.create(new_shop_attrs)

            # XXX: If this menu was responsible by one staff(or no need manpower), then for sure, all the staffs had capability to handle it.
            if menu.min_staffs_number <= 1
              menu.staff_menus.update_all(max_customers: checked_menu_shops.map { |attr| attr[:max_seat_number] }.max)
            end
          end
        # when "sale_template_variables", "introduction_video_url", "flow", "quantity"
        #   sale_page.update(attrs.slice(update_attribute))
        # when "normal_price"
        #   sale_page.update(normal_price_amount_cents: attrs[:normal_price])
        # when "selling_price"
        #   sale_page.update(selling_price_amount_cents: attrs[:selling_price])
        # when "why_content"
        #   picture = attrs[:why_content].delete(:picture)
        #
        #   sale_page.update(content: attrs[:why_content])
        #   if picture
        #     sale_page.picture.purge_later
        #     sale_page.update(picture: picture)
        #   end
        # when "end_time"
        #   sale_page.update(selling_end_at: attrs[:selling_end_at] ? Time.zone.parse(attrs[:selling_end_at]).end_of_day : nil)
        # when "start_time"
        #   sale_page.update(selling_start_at: attrs[:selling_start_at] ? Time.zone.parse(attrs[:selling_start_at]).beginning_of_day : nil)
        # when "staff"
        #   responsible_staff = sale_page.user.staffs.find(attrs[:staff][:id])
        #   sale_page.update(staff: responsible_staff)
        #   if attrs[:staff][:picture]
        #     responsible_staff.picture.purge
        #     responsible_staff.picture = attrs[:staff][:picture]
        #   end
        #   responsible_staff.introduction = attrs[:staff][:introduction]
        #   responsible_staff.save!
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
  end
end

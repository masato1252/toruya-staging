# frozen_string_literal: true

module BookingOptions
  class Update < ActiveInteraction::Base
    object :booking_option, class: "BookingOption"
    string :update_attribute

    hash :attrs, default: nil do
      string :name, default: nil
      string :display_name, default: nil
      string :memo, default: nil
      boolean :menu_restrict_order, default: false

      integer :amount_cents, default: nil
      integer :ticket_quota, default: 1
      integer :ticket_expire_month, default: 1
      boolean :tax_include, default: false

      string :start_at_date_part, default: nil
      string :start_at_time_part, default: nil

      string :end_at_date_part, default: nil
      string :end_at_time_part, default: nil

      # For adding a new option with existing menu
      integer :new_menu_id, default: nil
      integer :new_menu_required_time, default: nil

      # For adding a new menu
      string :new_menu_name, default: nil
      integer :new_menu_minutes, default: nil
      boolean :new_menu_online_state, default: false
      integer :new_menu_max_seat_number, default: 1

      # For changing menu priority
      array :sorted_menus_ids, default: []

      # For changing menu required_time
      integer :menu_id, default: nil
      integer :menu_required_time, default: nil

      array :booking_page_ids, default: []
    end

    def execute
      booking_option.with_lock do
        case update_attribute
        when "name"
          booking_option.update(name: attrs[:name])
          # if this booking option only has one menu, update the minutes
          if booking_option.booking_option_menus.count == 1
            booking_option.menus.first.update(name: attrs[:name], short_name: attrs[:name])
          end
        when "display_name", "memo"
          booking_option.update(attrs.slice(update_attribute))

          if user.line_keyword_booking_option_ids.include?(booking_option.id.to_s)
            compose(BookingOptions::SyncBookingPage, booking_option: booking_option)
          end
        when "menu_restrict_order"
          booking_option.update(attrs.slice(update_attribute))
        when "booking_page_ids"
          booking_option.update(booking_page_ids: attrs[:booking_page_ids])
        when "new_pure_menu"
          ApplicationRecord.transaction do
            category = user.categories.find_or_create_by(name: I18n.t("user_bot.dashboards.booking_page_creation.default_category_name"))

            menu = compose(
              Menus::Update,
              menu: user.menus.new,
              attrs: {
                name: attrs[:new_menu_name],
                short_name: attrs[:new_menu_name],
                minutes: attrs[:new_menu_minutes],
                online: attrs[:new_menu_online_state],
                interval: 0,
                min_staffs_number: 1,
                category_ids: [category.id],
                shop_menus_attributes: user.shop_ids.map do |shop_id|
                  {
                    shop_id: shop_id,
                    max_seat_number: attrs[:new_menu_max_seat_number]
                  }
                end,
                staff_menus_attributes: [
                  {
                    staff_id: user.current_staff(user).id,
                    priority: 0,
                    max_customers: 1
                  }
                ]
              },
              reservation_setting_id: reservation_setting.id,
              menu_reservation_setting_rule_attributes: {
                start_date: Date.today
              }
            )

            booking_option.booking_option_menus.create!(
              menu_id: menu.id,
              priority: booking_option.booking_option_menus.count,
              required_time: menu.minutes
            )

            booking_option.update!(minutes: booking_option.booking_option_menus.sum(:required_time))
          end
        when "new_menu"
          if attrs["new_menu_id"]
            option_menu = booking_option.booking_option_menus.create(
              menu_id: attrs["new_menu_id"],
              priority: booking_option.booking_option_menus.count,
              required_time: attrs["new_menu_required_time"]
            )

            if option_menu.valid?
              booking_option.update(minutes: booking_option.booking_option_menus.sum(:required_time))
            else
              errors.merge!(option_menu.errors)
            end
          else
            errors.add(:base, I18n.t("errors.not_enough_info"))
          end
        when "start_at"
          booking_option.update(start_at: attrs[:start_at_date_part] ? Time.zone.parse("#{attrs[:start_at_date_part]}-#{attrs[:start_at_time_part]}") : nil)
        when "end_at"
          booking_option.update(end_at: attrs[:end_at_date_part] ? Time.zone.parse("#{attrs[:end_at_date_part]}-#{attrs[:end_at_time_part]}") : nil)
        when "price"
          booking_option.update(
            amount: Money.new(attrs[:amount_cents], user.currency),
            ticket_quota: attrs[:ticket_quota],
            ticket_expire_month: attrs[:ticket_expire_month],
            tax_include: attrs[:tax_include]
          )
        when "menus_priority"
          attrs["sorted_menus_ids"].each.with_index do |menu_id, index|
            booking_option.booking_option_menus.find_by(menu_id: menu_id).update(priority: index)
          end
        when "menu_required_time"
          booking_option_menu = booking_option.booking_option_menus.find_by(menu_id: attrs["menu_id"])
          if booking_option_menu.update(required_time: attrs["menu_required_time"])
            # if this booking option only has one menu, update the minutes
            if booking_option.booking_option_menus.count == 1
              booking_option.menus.first.update(minutes: attrs["menu_required_time"])
            end

            BookingOption.where(id: booking_option.id).each do |booking_option|
              booking_option.update!(minutes: booking_option.booking_option_menus.sum(:required_time))
            end
          end
          errors.merge!(booking_option_menu.errors)
        end

        if booking_option.errors.present?
          errors.merge!(booking_option.errors)
        else
          booking_page_ids = BookingPageOption.where(booking_option: booking_option).pluck(:booking_page_id)
          BookingPage.where(id: booking_page_ids).find_each do |booking_page|
            ::BookingPageCacheJob.perform_later(booking_page)
          end
        end

        booking_option
      end
    end

    private

    def user
      @user ||= booking_option.user
    end

    def reservation_setting
      user.reservation_settings.where(day_type: ReservationSetting::BUSINESS_DAYS, start_time: nil, end_time: nil).first ||
        user.reservation_settings.create(
          name: I18n.t("common.full_working_time"),
          short_name: I18n.t("common.full_working_time"),
          day_type: ReservationSetting::BUSINESS_DAYS)
    end
  end
end
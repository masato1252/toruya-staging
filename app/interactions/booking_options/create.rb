# frozen_string_literal: true

module BookingOptions
  class Create < ActiveInteraction::Base
    object :user
    # for adding a new option from existing option
    integer :new_option_id, default: nil

    # For adding a new menu
    string :new_menu_name, default: nil
    string :new_memo, default: nil
    integer :new_menu_minutes, default: nil
    integer :new_menu_price, default: nil
    boolean :new_menu_online_state, default: false
    integer :new_menu_max_seat_number, default: 1

    # For adding a new option with existing menu
    integer :new_menu_id, default: nil
    integer :new_menu_required_time, default: nil

    integer :ticket_quota, default: 1
    integer :ticket_expire_month, default: 1
    array :booking_page_ids, default: [] do
      integer
    end

    def execute
      ApplicationRecord.transaction do
        if new_option_id
          new_booking_option = BookingOption.find(new_option_id)
        else
          menu =
            if new_menu_id
              Menu.find(new_menu_id)
            else
              category = user.categories.find_or_create_by(name: I18n.t("user_bot.dashboards.booking_page_creation.default_category_name"))
              compose(
                Menus::Update,
                menu: user.menus.new,
                attrs: {
                  name: new_menu_name,
                  short_name: new_menu_name,
                  minutes: new_menu_minutes,
                  online: new_menu_online_state,
                  interval: 0,
                  min_staffs_number: 1,
                  category_ids: [category.id],
                  shop_menus_attributes: [ { shop_id: shop.id, max_seat_number: new_menu_max_seat_number } ],
                  staff_menus_attributes: [ { staff_id: user.current_staff(user).id, priority: 0, max_customers: 1 } ]
                },
                reservation_setting_id: reservation_setting.id,
                menu_reservation_setting_rule_attributes: { start_date: Date.today }
              )
          end

          default_booking_option_attrs = {
            name: menu.name,
            display_name: menu.name,
            minutes: menu.minutes,
            amount_cents: new_menu_price,
            ticket_quota: ticket_quota,
            ticket_expire_month: ticket_expire_month,
            tax_include: true,
            memo: new_memo,
            menus: {
              "0" => { 'value' => menu.id, "priority" => 0, "required_time" => menu.minutes },
            }
          }

          new_booking_option = compose(
            BookingOptions::Save,
            booking_option: user.booking_options.new,
            attrs: default_booking_option_attrs
          )
        end

        if booking_page_ids.present?
          BookingPage.where(id: booking_page_ids).each do |booking_page|
            booking_page.update(booking_option_ids: booking_page.booking_option_ids.push(new_booking_option.id).uniq )
          end

          BookingPage.find(booking_page_ids.first)
        elsif !user.booking_pages.exists?
          compose(
            ::BookingPages::SmartCreate,
            attrs: {
              super_user_id: user.id,
              shop_id: shop.id,
              menu_id: menu.id,
              booking_option_id: new_booking_option.id
            }
          )
        end
      end
    end

    private

    def reservation_setting
      user.reservation_settings.where(day_type: ReservationSetting::BUSINESS_DAYS, start_time: nil, end_time: nil).first ||
        user.reservation_settings.create(
          name: I18n.t("common.full_working_time"),
          short_name: I18n.t("common.full_working_time"),
          day_type: ReservationSetting::BUSINESS_DAYS)
    end

    def shop
      user.shops.first
    end
  end
end

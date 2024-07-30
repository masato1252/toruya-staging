# frozen_string_literal: true

module BookingPages
  class SmartCreate < ActiveInteraction::Base
    hash :attrs do
      integer :super_user_id
      integer :shop_id
      integer :menu_id, default: nil
      integer :booking_option_id, default: nil
      integer :new_booking_option_price, default: nil
      boolean :new_booking_option_tax_include, default: nil
      integer :ticket_quota, default: 1
      integer :ticket_expire_month, default: 1
      string :new_menu_name, default: nil
      integer :new_menu_minutes, default: nil
      boolean :new_menu_online, default: false
      string :note, default: nil
      boolean :rich_menu_only, default: false
    end

    def execute
      ApplicationRecord.transaction do
        if !attrs[:booking_option_id]
          default_booking_option_attrs = {
            name: menu.name,
            display_name: menu.name,
            minutes: menu.minutes,
            amount_cents: attrs[:new_booking_option_price],
            tax_include: attrs[:new_booking_option_tax_include],
            ticket_quota: attrs[:ticket_quota],
            ticket_expire_month: attrs[:ticket_expire_month],
            menus: {
              "0" => { 'value' => menu.id, "priority" => 0, "required_time" => menu.minutes },
            }
          }

          new_booking_option = compose(
            BookingOptions::Save,
            booking_option: super_user.booking_options.new,
            attrs: default_booking_option_attrs
          )
        end

        default_booking_page_attrs = {
          name: I18n.t("user_bot.dashboards.booking_page_creation.default_label", menu_name: menu&.short_name || booking_option.name),
          title: I18n.t("user_bot.dashboards.booking_page_creation.default_label", menu_name: menu&.short_name || booking_option.name),
          greeting: I18n.t("user_bot.dashboards.booking_page_creation.default_greeting", menu_name: menu&.short_name || booking_option.name),
          shop_id: shop.id,
          note: attrs[:note],
          options: {
            "0" => { 'value' => attrs[:booking_option_id] || new_booking_option.id },
          },
          draft: false,
          rich_menu_only: attrs[:rich_menu_only]
        }

        booking_page = compose(
          BookingPages::Save,
          booking_page: super_user.booking_pages.new,
          attrs: default_booking_page_attrs
        )

        ::BookingPageCacheJob.perform_later(booking_page)

        case super_user.booking_pages.count
        when 1
          Notifiers::Users::BookingPages::FirstCreation.run(receiver: super_user)
        when 2
          Notifiers::Users::BookingPages::SecondCreation.run(receiver: super_user)
        when 11
          Notifiers::Users::BookingPages::EleventhCreation.run(receiver: super_user)
        end

        booking_page
      end
    end

    private

    def shop
      @shop ||= Shop.find(attrs[:shop_id])
    end

    def menu
      @menu ||= new_menu || shop.menus.find_by(id: attrs[:menu_id])
    end

    def new_menu
      if attrs[:new_menu_name] && attrs[:new_menu_minutes]
        category = super_user.categories.find_or_create_by(name: I18n.t("user_bot.dashboards.booking_page_creation.default_category_name"))

        Menus::Update.run!(
          menu: super_user.menus.new,
          attrs: {
            name: attrs[:new_menu_name],
            short_name: attrs[:new_menu_name],
            minutes: attrs[:new_menu_minutes],
            online: attrs[:new_menu_online],
            interval: 0,
            min_staffs_number: 1,
            category_ids: [category.id],
            shop_menus_attributes: [
              {
                shop_id: shop.id,
                max_seat_number: 1
              }
            ],
            staff_menus_attributes: [
              {
                staff_id: super_user.current_staff(super_user).id,
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
      end
    end

    def reservation_setting
      super_user.reservation_settings.where(day_type: ReservationSetting::BUSINESS_DAYS, start_time: nil, end_time: nil).first ||
        super_user.reservation_settings.create(
          name: I18n.t("common.full_working_time"),
          short_name: I18n.t("common.full_working_time"),
          day_type: ReservationSetting::BUSINESS_DAYS)
    end

    def booking_option
      @booking_option ||= super_user.booking_options.find_by(id: attrs[:booking_option_id])
    end

    def super_user
      @user ||= User.find(attrs[:super_user_id])
    end

    def booking_page_name
      if attrs[:rich_menu_only]
        BookingOption.find(attrs[:booking_option_id]).name
      elsif super_user.booking_pages.exists?
        "#{shop.name}(#{super_user.booking_pages.count})"
      else
        shop.name
      end
    end
  end
end

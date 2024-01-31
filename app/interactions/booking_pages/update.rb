# frozen_string_literal: true

module BookingPages
  class Update < ActiveInteraction::Base
    validate :validate_booking_option

    object :booking_page, class: "BookingPage"
    string :update_attribute

    hash :attrs, default: nil, strip: false do
      string :name, default: nil
      string :title, default: nil
      boolean :draft, default: true
      boolean :line_sharing, default: true
      boolean :online_payment_enabled, default: false
      integer :shop_id, default: nil
      integer :booking_limit_day, default: 1
      string :greeting, default: nil
      string :note, default: nil
      integer :interval, default: 30
      array :booking_start_times, default: nil do
        hash do
          string :start_time
        end
      end
      boolean :overbooking_restriction, default: true

      integer :new_option_id, default: nil

      # For adding a new option with existing menu
      integer :new_menu_id, default: nil
      integer :new_menu_required_time, default: nil

      # For adding a new menu
      string :new_menu_name, default: nil
      integer :new_menu_minutes, default: nil
      integer :new_menu_price, default: nil
      boolean :new_menu_online_state, default: false

      string :start_at_date_part, default: nil
      string :start_at_time_part, default: nil
      string :end_at_date_part, default: nil
      string :end_at_time_part, default: nil
      # special_dates array
      # [
      #   {"start_at_date_part"=>"2019-04-22", "start_at_time_part"=>"01:00", "end_at_date_part"=>"2019-04-22", "end_at_time_part"=>"12:59"},
      #   {"start_at_date_part"=>"2019-04-22", "start_at_time_part"=>"01:00", "end_at_date_part"=>"2019-04-22", "end_at_time_part"=>"12:59"}
      # [
      string :booking_type, default: nil # event_booking, only_special_dates_booking, and any
      array :special_dates, default: nil do
        hash do
          string :start_at_date_part
          string :start_at_time_part
          string :end_at_date_part
          string :end_at_time_part
        end
      end
    end

    def execute
      booking_type = attrs.delete(:booking_type)
      booking_options = attrs.delete(:options)
      new_option_id = attrs.delete(:new_option_id)
      special_dates = attrs.delete(:special_dates)

      booking_page.transaction do
        case update_attribute
        when "booking_type"
          booking_page.booking_page_special_dates.destroy_all

          if special_dates
            special_dates.each do |date_times|
              booking_page.booking_page_special_dates.create(date_times)
            end
          end
          booking_page.update(event_booking: booking_type == "event_booking")
        when "new_option_menu"
          ApplicationRecord.transaction do

            menu =
              if attrs[:new_menu_id]
                Menu.find(attrs[:new_menu_id])
              else
                category = user.categories.find_or_create_by(name: I18n.t("user_bot.dashboards.booking_page_creation.default_category_name"))

                compose(
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
                    shop_menus_attributes: [
                      {
                        shop_id: booking_page.shop_id,
                        max_seat_number: 1
                      }
                    ],
                    staff_menus_attributes: user.staff_ids.map do |staff_id|
                      {
                        staff_id: staff_id,
                        priority: 0,
                        max_customers: 1
                      }
                    end
                  },
                  reservation_setting_id: reservation_setting.id,
                  menu_reservation_setting_rule_attributes: {
                    start_date: Date.today
                  }
                )
              end

            default_booking_option_attrs = {
              name: menu.name,
              display_name: menu.name,
              minutes: attrs[:new_menu_required_time] || menu.minutes,
              amount_cents: attrs[:new_menu_price],
              tax_include: true,
              menus: {
                "0" => { 'value' => menu.id, "priority" => 0, "required_time" => attrs[:new_menu_required_time] || menu.minutes },
              }
            }

            new_booking_option = compose(
              BookingOptions::Save,
              booking_option: user.booking_options.new,
              attrs: default_booking_option_attrs
            )

            booking_page.update(booking_option_ids: booking_page.booking_option_ids.push(new_booking_option.id).uniq )
          end
        when "new_option"
          booking_page.update(booking_option_ids: booking_page.booking_option_ids.push(new_option_id).uniq )
        when "start_at"
          booking_page.update(start_at: attrs[:start_at_date_part] ? Time.zone.parse("#{attrs[:start_at_date_part]}-#{attrs[:start_at_time_part]}") : nil)
        when "end_at"
          booking_page.update(end_at: attrs[:end_at_date_part] ? Time.zone.parse("#{attrs[:end_at_date_part]}-#{attrs[:end_at_time_part]}") : nil)
        when "booking_time"
          booking_page.update(
            interval: attrs[:interval],
            specific_booking_start_times: attrs[:booking_start_times].map{|h| h[:start_time]}.sort.uniq
          )
        when "name", "title", "draft", "shop_id", "booking_limit_day", "greeting", "note", "overbooking_restriction", "online_payment_enabled"
          booking_page.update(attrs.slice(update_attribute))
        when "line_sharing"
          booking_page.update(attrs.slice(update_attribute))

          BookingPages::ChangeLineSharing.run(booking_page: booking_page)
        end

        if booking_page.errors.present?
          errors.merge!(booking_page.errors)
        end

        booking_page
      end
    end

    private

    def validate_booking_option
      if update_attribute == "shop_id"
        shop = Shop.find(attrs[:shop_id])

        new_shop_available_booking_options = compose(BookingPages::AvailableBookingOptions, shop: shop)

        booking_page.booking_options.each do |booking_option|
          if new_shop_available_booking_options.map(&:id).exclude?(booking_option.id)
            errors.add(:attrs, :unavailable_booking_option_exists)
            break
          end
        end
      end
    end

    def user
      @user ||= booking_page.user
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

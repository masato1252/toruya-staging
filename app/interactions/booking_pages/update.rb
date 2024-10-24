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
      boolean :social_account_skippable, default: false
      boolean :line_sharing, default: true
      boolean :customer_cancel_request, default: true
      integer :customer_cancel_request_before_day, default: 1
      integer :shop_id, default: nil
      integer :booking_limit_day, default: 0
      integer :booking_limit_hours, default: 0
      integer :bookable_restriction_months, default: nil
      string :greeting, default: nil
      string :note, default: nil
      integer :interval, default: 30
      array :booking_start_times, default: nil do
        hash do
          string :start_time
        end
      end
      boolean :overbooking_restriction, default: true
      boolean :multiple_selection, default: false

      string :payment_option, default: "offline"
      boolean :customer_address_required, default: true
      array :booking_page_online_payment_options_ids, default: []

      # for adding a new option from existing option
      integer :new_option_id, default: nil

      # For adding a new option with existing menu
      integer :new_menu_id, default: nil
      integer :new_menu_required_time, default: nil

      # For adding a new menu
      string :new_menu_name, default: nil
      integer :new_menu_minutes, default: nil
      integer :new_menu_price, default: nil
      boolean :new_menu_online_state, default: false
      integer :new_menu_max_seat_number, default: 1
      integer :ticket_quota, default: 1
      integer :ticket_expire_month, default: 1

      string :start_at_date_part, default: nil
      string :start_at_time_part, default: nil
      string :end_at_date_part, default: nil
      string :end_at_time_part, default: nil
      string :cut_off_time_date_part, default: nil
      string :cut_off_time_time_part, default: nil
      # special_dates array
      # [
      #   {"start_at_date_part"=>"2019-04-22", "start_at_time_part"=>"01:00", "end_at_date_part"=>"2019-04-22", "end_at_time_part"=>"12:59"},
      #   {"start_at_date_part"=>"2019-04-22", "start_at_time_part"=>"01:00", "end_at_date_part"=>"2019-04-22", "end_at_time_part"=>"12:59"}
      # [
      string :booking_type, default: nil # event_booking, only_special_dates_booking, business_schedules_booking, and any
      array :business_schedules, default: [] do
        hash do
          integer :day_of_week
          string :start_time
          string :end_time
        end
      end
      array :special_dates, default: nil do
        hash do
          string :start_at_date_part
          string :start_at_time_part
          string :end_at_date_part
          string :end_at_time_part
        end
      end

      integer :requirement_sale_page_id, default: nil
      integer :requirement_online_service_id, default: nil
    end

    def execute
      booking_type = attrs.delete(:booking_type)
      booking_options = attrs.delete(:options)
      new_option_id = attrs.delete(:new_option_id)
      special_dates = attrs.delete(:special_dates)
      business_schedules = attrs.delete(:business_schedules)
      payment_option_type = attrs.delete(:payment_option_type)

      booking_page.transaction do
        case update_attribute
        when "requirements"
          booking_page.product_requirement&.destroy
          if !attrs[:requirement_online_service_id].zero?
            compose(
              ProductRequirements::Create,
              requirer: booking_page,
              sale_page_id: attrs[:requirement_sale_page_id],
              requirement: OnlineService.find(attrs[:requirement_online_service_id])
            )
          end
        when "booking_type"
          booking_page.booking_page_special_dates.destroy_all
          booking_page.business_schedules.destroy_all

          if special_dates.present?
            special_dates.each do |date_times|
              booking_page.booking_page_special_dates.create(date_times)
            end
          end

          if business_schedules.present?
            business_schedules.each do |business_schedule|
              booking_page.business_schedules.create!(
                business_state: "opened",
                shop: booking_page.shop,
                day_of_week: business_schedule[:day_of_week],
                start_time: business_schedule[:start_time],
                end_time: business_schedule[:end_time]
              )
            end
          end

          booking_page.update(event_booking: booking_type == "event_booking")
        when "new_option_menu", "new_option_existing_menu"
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
                        max_seat_number: attrs[:new_menu_max_seat_number]
                      }
                    ],
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
              end

            default_booking_option_attrs = {
              name: menu.name,
              display_name: menu.name,
              minutes: attrs[:new_menu_required_time] || menu.minutes,
              amount_cents: attrs[:new_menu_price],
              ticket_quota: attrs[:ticket_quota],
              ticket_expire_month: attrs[:ticket_expire_month],
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
            update_new_booking_page_option_payment_option(booking_page.booking_page_options.find_by(booking_option_id: new_booking_option.id))
          end
        when "new_option"
          booking_page.update(booking_option_ids: booking_page.booking_option_ids.push(new_option_id).uniq )
          update_new_booking_page_option_payment_option(booking_page.booking_page_options.find_by(booking_option_id: new_option_id))
        when "start_at"
          booking_page.update(start_at: attrs[:start_at_date_part] ? Time.zone.parse("#{attrs[:start_at_date_part]}-#{attrs[:start_at_time_part]}") : nil)
        when "end_at"
          booking_page.update(end_at: attrs[:end_at_date_part] ? Time.zone.parse("#{attrs[:end_at_date_part]}-#{attrs[:end_at_time_part]}") : nil)
        when "cut_off_time"
          booking_page.update(cut_off_time: attrs[:cut_off_time_date_part] ? Time.zone.parse("#{attrs[:cut_off_time_date_part]}-#{attrs[:cut_off_time_time_part]}") : nil)
        when "booking_time"
          booking_page.update(
            interval: attrs[:interval],
            specific_booking_start_times: attrs[:booking_start_times].map{|h| h[:start_time]}.sort.uniq
          )
        when "booking_available_period"
          booking_page.update(
            booking_limit_day: attrs[:booking_limit_day],
            booking_limit_hours: attrs[:booking_limit_hours],
            bookable_restriction_months: attrs[:bookable_restriction_months],
            end_at: attrs[:end_at_date_part] ? Time.zone.parse("#{attrs[:end_at_date_part]}-#{attrs[:end_at_time_part]}") : nil,
            start_at: attrs[:start_at_date_part] ? Time.zone.parse("#{attrs[:start_at_date_part]}-#{attrs[:start_at_time_part]}") : nil,
            cut_off_time: attrs[:cut_off_time_date_part] ? Time.zone.parse("#{attrs[:cut_off_time_date_part]}-#{attrs[:cut_off_time_time_part]}") : nil
          )
        when "name", "title", "draft", "shop_id", "greeting", "note", "overbooking_restriction", "social_account_skippable", "multiple_selection"
          booking_page.update(attrs.slice(update_attribute))
        when "customer_cancel_request"
          booking_page.update(
            customer_cancel_request: attrs[:customer_cancel_request],
            customer_cancel_request_before_day: attrs[:customer_cancel_request_before_day]
          )
        when "payment_option"
          case attrs[:payment_option]
          when "online"
            booking_page.booking_page_options.update_all(online_payment_enabled: true)
          when "offline"
            booking_page.booking_page_options.update_all(online_payment_enabled: false)
          when "custom"
            booking_page.booking_page_options.where(id: attrs[:booking_page_online_payment_options_ids]).update_all(online_payment_enabled: true)
            booking_page.booking_page_options.where.not(id: attrs[:booking_page_online_payment_options_ids]).update_all(online_payment_enabled: false)
          end
          booking_page.payment_option = attrs[:payment_option]
          booking_page.save
        when "customer_address_required"
          booking_page.update(customer_address_required: attrs[:customer_address_required])
        when "line_sharing"
          booking_page.update(attrs.slice(update_attribute))

          BookingPages::ChangeLineSharing.run(booking_page: booking_page)
        end

        if booking_page.errors.present?
          errors.merge!(booking_page.errors)
        else
          ::BookingPageCacheJob.perform_later(booking_page)
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

    def update_new_booking_page_option_payment_option(booking_page_option)
      if booking_page.payment_option == "online"
        booking_page.booking_page_options.update_all(online_payment_enabled: true)
      elsif booking_page.payment_option == "offline"
        booking_page.booking_page_options.update_all(online_payment_enabled: false)
      elsif booking_page.payment_option == "custom"
        custom_online_payment_options_count = booking_page.booking_page_options.where(online_payment_enabled: true).count
        custom_offline_payment_options_count = booking_page.booking_page_options.where(online_payment_enabled: false).count

        if custom_online_payment_options_count > custom_offline_payment_options_count 
          booking_page_option.update(online_payment_enabled: true)
        else
          booking_page_option.update(online_payment_enabled: false)
        end
      end
    end
  end
end

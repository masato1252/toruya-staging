module Reservable
  class Menus < ActiveInteraction::Base
    include SharedMethods

    set_callback :type_check, :before do
      self.number_of_customer = (number_of_customer.zero? || number_of_customer.nil?) ? 1 : number_of_customer
    end

    object :shop
    object :business_time_range, class: Range
    integer :number_of_customer, default: 1
    integer :reservation_id, default: nil

    def execute
      # shop have custom_schedules(closed temporary) during reservation time.
      return Menu.none if custom_schedules_for_shop.exists?

      scoped = workable_menus.where.not("staff_menus.staff_id" => reserved_staff_ids)

      # Menu with customers need to be afforded by staff
      # staff work for menu0 would be available here.
      # XXX: Find Second largest Value refactor: http://stackoverflow.com/questions/4910930/trying-to-find-the-second-largest-value-in-a-column-postgres-sql
      no_reservation_except_menu0_menus = scoped.select("menus.*, max(shop_menus.max_seat_number) as max_seat_number").group("menus.id").having("
      CASE
        WHEN menus.min_staffs_number = 1 THEN LEAST(max(staff_menus.max_customers), max(shop_menus.max_seat_number)) >= #{number_of_customer}
        WHEN menus.min_staffs_number > 1 THEN
          count(DISTINCT(staff_menus.staff_id)) >= menus.min_staffs_number AND
        #{number_of_customer} <= MAX(shop_menus.max_seat_number) AND
          (COALESCE((array_agg(staff_menus.max_customers order by staff_menus.max_customers desc))[2], 0) + MAX(staff_menus.max_customers)) >= #{number_of_customer}
        WHEN menus.min_staffs_number = 0 THEN FALSE
        ELSE TRUE
      END")

      no_reservation_except_menu0_menus = no_reservation_except_menu0_menus.map do |menu|
        Options::MenuOption.new(id: menu.id, name: menu.display_name, min_staffs_number: menu.min_staffs_number, available_seat: menu.max_seat_number)
      end

      # XXX: this intersection was used now, so below reservation.menus.first is a temporary fix.
      reservation_menus = overlap_reservations.group_by { |reservation| reservation.menus.first }.map do |menu, reservations|
        menu_max_seat_number = menu.shop_menus.find_by(shop: shop).max_seat_number
        customers_amount_of_reservations = shop.reservations.sum(&:count_of_customers)
        is_enough_seat = menu_max_seat_number >= number_of_customer + customers_amount_of_reservations
        next unless is_enough_seat

        if menu.min_staffs_number == 0
          Options::MenuOption.new(id: menu.id, name: menu.display_name,
                                  min_staffs_number: menu.min_staffs_number,
                                  available_seat: menu_max_seat_number - customers_amount_of_reservations)
        elsif menu.min_staffs_number == 1
          if reservations.any? { |reservation|
            reservation.staffs.first.staff_menus.find_by(menu: menu).max_customers >= number_of_customer + reservation.reservation_customers.active.count
          }

          Options::MenuOption.new(id: menu.id, name: menu.display_name,
                                  min_staffs_number: menu.min_staffs_number,
                                  available_seat: menu_max_seat_number - customers_amount_of_reservations)
          end
        elsif menu.min_staffs_number > 1
          if reservations.any? { |reservation|
            staffs_max_customer = reservation.staffs.map { |staff| staff.staff_menus.find_by(menu: menu).max_customers }.min

            staffs_max_customer >= number_of_customer + reservation.reservation_customers.active.count
          }

          Options::MenuOption.new(id: menu.id, name: menu.display_name,
                                  min_staffs_number: menu.min_staffs_number,
                                  available_seat: menu_max_seat_number - customers_amount_of_reservations)
          end
        end
      end.compact

      (no_reservation_except_menu0_menus + reservation_menus + no_manpower_menus).uniq # staff for menu1, menu2 reservations, still could work for menu0 reservations
    end

    private

    def no_manpower_menus
      scoped = workable_menus.where("menus.min_staffs_number" => 0)

      _no_power_menus = scoped.select("menus.*").group("menus.id")
      _no_power_menus.map do |menu|
        reservations = overlap_reservations(menu.id)
        menu_max_seat_number = menu.shop_menus.find_by(shop: shop).max_seat_number
        customers_amount_of_reservations = reservations.sum(&:count_of_customers)

        if menu_max_seat_number >= number_of_customer + customers_amount_of_reservations
          Options::MenuOption.new(id: menu.id, name: menu.display_name,
                                  min_staffs_number: 0,
                                  available_seat: menu_max_seat_number - customers_amount_of_reservations)
        end
      end.compact
    end

    def custom_schedules_for_shop
      @custom_schedules_for_shop ||= shop.custom_schedules.for_shop.closed.where("custom_schedules.start_time < ? and custom_schedules.end_time > ?", end_time, start_time)
    end

    def workable_menus
      # menu that has reservation_setting and menu_reservation_setting_rules
      return @workable_menus_scoped if defined?(@workable_menus_scoped)

      @workable_menus_scoped = shop.menus.
        joins(:reservation_setting,
              :menu_reservation_setting_rule).
        joins("LEFT OUTER JOIN staff_menus on staff_menus.menu_id = menus.id
               LEFT OUTER JOIN business_schedules ON business_schedules.staff_id = staff_menus.staff_id AND
                                                     business_schedules.shop_id = #{shop.id}
               LEFT OUTER JOIN custom_schedules opened_custom_schedules ON opened_custom_schedules.staff_id = staff_menus.staff_id AND
                                                                           opened_custom_schedules.shop_id = #{shop.id} AND
                                                                           opened_custom_schedules.open = true
               LEFT OUTER JOIN shop_menu_repeating_dates ON shop_menu_repeating_dates.menu_id = menus.id AND
                                                            shop_menu_repeating_dates.shop_id = #{shop.id}"
             )

      # menus's staffs could not had reservation during reservation time
      # menus time is longer enough
      @workable_menus_scoped = @workable_menus_scoped.
        where.not("staff_menus.staff_id" => closed_custom_schedules_staff_ids).
        where("minutes <= ?", distance_in_minutes)

      # Menu staffs schedule need to be full_time or work during reservation time
      @workable_menus_scoped = @workable_menus_scoped.
        where("business_schedules.full_time = ?", true).
      or(
        @workable_menus_scoped.
          where("business_schedules.business_state = ? and business_schedules.day_of_week = ?", "opened", start_time.wday).
          where("(business_schedules.start_time + '#{::Time.zone.now.utc_offset} seconds'::INTERVAL)::time <= ? and
                 (business_schedules.end_time + '#{::Time.zone.now.utc_offset} seconds'::INTERVAL)::time >= ?",
                 start_time.to_s(:time), end_time.to_s(:time))
      ).
      or(
        @workable_menus_scoped.
          where("opened_custom_schedules.start_time <= ? and opened_custom_schedules.end_time >= ?", start_time, end_time)
      )

      # Menu need reservation setting to be reserved
      @workable_menus_scoped = @workable_menus_scoped.where("menu_reservation_setting_rules.start_date <= ?", today)

      @workable_menus_scoped = @workable_menus_scoped.where("menu_reservation_setting_rules.reservation_type is NULL AND menu_reservation_setting_rules.end_date is NULL").
        or(
          @workable_menus_scoped.where("menu_reservation_setting_rules.reservation_type = 'date' AND menu_reservation_setting_rules.end_date >= ?", today)
        ).
        or(
          @workable_menus_scoped.where("menu_reservation_setting_rules.reservation_type = 'repeating' AND ? = ANY(shop_menu_repeating_dates.dates)", today)
        )

      @workable_menus_scoped = @workable_menus_scoped.
        where("(reservation_settings.start_time is NULL and reservation_settings.end_time is NULL) or
               ((reservation_settings.start_time + '#{::Time.zone.now.utc_offset} seconds'::INTERVAL)::time <= ? and
                (reservation_settings.end_time + '#{::Time.zone.now.utc_offset} seconds'::INTERVAL)::time >= ?)",
                start_time.to_s(:time), end_time.to_s(:time))

      @workable_menus_scoped = @workable_menus_scoped.where("reservation_settings.day_type = ?", "business_days").
      or(
        @workable_menus_scoped.
        where("reservation_settings.day_type = ? and ? = ANY(reservation_settings.days_of_week)", "weekly", "#{start_time.wday}")
      ).
      or(
        @workable_menus_scoped.where("reservation_settings.day_type = ? and reservation_settings.day = ?", "monthly", start_time.day)
      ).
      or(
        @workable_menus_scoped.where("reservation_settings.day_type = ? and reservation_settings.nth_of_week = ? and
               ? = ANY(reservation_settings.days_of_week)", "monthly", start_time.week_of_month, "#{start_time.wday}")
      )
    end

    def distance_in_minutes
      @distance_in_minutes ||= ((end_time - start_time)/60.0).round
    end
  end
end

module Reservable
  class Staffs < ActiveInteraction::Base
    include SharedMethods

    object :shop
    object :menu
    object :business_time_range, class: Range
    integer :number_of_customer, default: 1
    integer :reservation_id, default: nil

    def execute
      reservations = overlap_reservations(menu.id)

      menu_max_seat_number = menu.shop_menus.find_by(shop: shop).max_seat_number
      customers_amount_of_reservations = reservations.sum(&:count_of_customers)
      is_enough_seat = menu_max_seat_number >= number_of_customer + customers_amount_of_reservations

      return [] unless is_enough_seat

      scoped = menu.staffs.
        joins("LEFT OUTER JOIN business_schedules ON business_schedules.staff_id = staffs.id AND business_schedules.shop_id = #{shop.id}").
      includes(:staff_menus).
        where.not("staff_menus.staff_id" => (reserved_staff_ids + custom_schedules_staff_ids).uniq)

      scoped = scoped.
        where("business_schedules.full_time = ?", true).
        or(
          scoped.
          where("business_schedules.business_state = ? and business_schedules.day_of_week = ?", "opened", start_time.wday).
          where("business_schedules.start_time::time <= ? and business_schedules.end_time::time >= ?", start_time, end_time)
      )

      no_reservation_except_menu0_staffs = scoped.select("staffs.*, max(staff_menus.max_customers) as max_customers").group("staffs.id")

      no_reservation_except_menu0_staffs = if menu.min_staffs_number == 0
        no_reservation_except_menu0_staffs.map do |staff|
          Options::StaffOption.new(id: staff.id, name: staff.name,
                                   handable_customers: menu_max_seat_number - customers_amount_of_reservations)
        end
      else
        no_reservation_except_menu0_staffs.map do |staff|
          Options::StaffOption.new(id: staff.id, name: staff.name,
                                   handable_customers: staff.max_customers)
        end
      end

      reservation_staffs = []
      if menu.min_staffs_number == 0
        # Other reservation(menu1, menu2) staffs still could do this menu0 too.
        all_overlap_reservations = overlap_reservations(reservation_id)
        all_overlap_staffs = all_overlap_reservations.map {|reservation| reservation.staffs}.flatten
        reservation_staffs = all_overlap_staffs.find_all { |staff| staff.staff_menus.where(menu: menu).exists? }

        reservation_staffs = reservation_staffs.map do |staff|
          Options::StaffOption.new(id: staff.id, name: staff.name,
                                   handable_customers: menu_max_seat_number - customers_amount_of_reservations)
        end
      elsif menu.min_staffs_number == 1
        reservation_staffs = reservations.map do |reservation|
          staff = reservation.staffs.first
          staff_max_customer = staff.staff_menus.find_by(menu: menu).max_customers

          if staff_max_customer >= number_of_customer + reservation.count_of_customers
            Options::StaffOption.new(id: staff.id, name: staff.name,
                                     handable_customers: staff_max_customer - reservation.count_of_customers )
          end
        end.compact.flatten
      elsif menu.min_staffs_number > 1
        reservation_staffs = reservations.map do |reservation|
          staffs_max_customer = reservation.staffs.map { |staff| staff.staff_menus.find_by(menu: menu).max_customers }.min

          if staffs_max_customer >= number_of_customer + reservation.count_of_customers
            reservation.staffs.map do |staff|
              Options::StaffOption.new(id: staff.id, name: staff.name,
                                       handable_customers: staffs_max_customer - reservation.count_of_customers )
            end
          end
        end.compact.flatten
      end

      # id, name, max_customers, occupied_customers_amount
      (no_reservation_except_menu0_staffs + reservation_staffs).flatten.uniq
    end

    private

    def start_time
      @start_time ||= business_time_range.first
    end

    def end_time
      @end_time ||= business_time_range.last + menu.interval.to_i.minutes
    end
  end
end

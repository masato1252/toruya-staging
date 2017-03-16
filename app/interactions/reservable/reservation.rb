module Reservable
  class Reservation < ActiveInteraction::Base
    include SharedMethods

    object :shop
    date :date
    object :business_time_range, class: Range, default: nil
    array :menu_ids, default: nil
    array :staff_ids, default: nil
    integer :reservation_id, default: nil
    integer :number_of_customer, default: 1

    def execute
      compose(Reservable::Time, shop: shop, date: date)

      return if menu_ids.blank? || business_time_range.blank?

      if new_reseravtion_time_interval < total_menus_working_time
        errors.add(:business_time_range, :too_short)
      end

      validate_seats_for_customers

      return if staff_ids.blank?

      working_day_staff_ids = working_day_staffs.map(&:id)
      staffs.includes(:staff_menus).each do |staff|
        if working_day_staff_ids.exclude?(staff.id)
          errors.add(:staff_ids, :unworking_staff, staff_name: staff.name)
        end

        validate_staffs_ability_for_customers(staff)
        validate_other_shop_reservation(staff)
        validate_same_shop_overlap_reservations(staff)
        validate_staff_ability(staff)
      end
    end

    private

    def total_menus_taking_time
      total_menus_working_time + last_menu_interval_time
    end

    def total_menus_working_time
      menus.sum(:minutes).minutes
    end

    def last_menu_interval_time
      menus.last.interval.minutes
    end

    def earliest_menu_start_time
    end

    def menus
      @menus ||= shop.menus.where(id: menu_ids)
    end

    def staffs
      @staffs ||= shop.staffs.where(id: staff_ids)
    end

    def validate_seats_for_customers
      shop_menus = shop.shop_menus.where(menu_id: menu_ids).to_a

      menus.each do |menu|
        if number_of_customer > shop_menus.find { |shop_menu| shop_menu.menu_id == menu.id }.max_seat_number
          errors.add(:menu_ids, :not_enough_seat, menu_name: menu.name)
        end
      end
    end

    def validate_staffs_ability_for_customers(staff)
      staff_menus = StaffMenu.where(staff_id: staff.id, menu_id: menu_ids)

      menus.each do |menu|
        if staff_menu = staff_menus.find { |staff_menu| staff_menu.menu_id == menu.id }
          if number_of_customer > staff_menu.max_customers
            errors.add(:staff_ids, :not_enough_ability, staff_name: staff.name, menu_name: menu.name)
          end
        end
      end
    end

    def working_day_staffs
      return @working_staffs if defined?(@working_staffs)

      scoped = staffs.
        joins("LEFT OUTER JOIN business_schedules ON business_schedules.staff_id = staffs.id AND business_schedules.shop_id = #{shop.id}
               LEFT OUTER JOIN custom_schedules opened_custom_schedules ON opened_custom_schedules.staff_id = staffs.id AND
                                                                           opened_custom_schedules.shop_id = #{shop.id} AND
                                                                           opened_custom_schedules.open = true
              ").
        includes(:staff_menus).
        where.not("staff_menus.staff_id" => (closed_custom_schedules_staff_ids).uniq)

      @working_staffs = scoped.
        where("business_schedules.full_time = ?", true).
        or(
          scoped.
          where("business_schedules.business_state = ? and business_schedules.day_of_week = ?", "opened", start_time.wday).
          where("business_schedules.start_time::time <= ? and business_schedules.end_time::time >= ?", start_time, ready_time)
        ).
        or(
          scoped.
          where("opened_custom_schedules.start_time <= ? and opened_custom_schedules.end_time >= ?", start_time, ready_time)
        ).to_a
    end

    def ready_time
      @ready_time ||= end_time
    end

    def new_reseravtion_time_interval
      end_time - start_time
    end

    def validate_other_shop_reservation(staff)
      other_shop_reservation_exist = ReservationStaff.joins(reservation: :menu).
        where.not(reservation_id: reservation_id.presence).
        where("reservation_staffs.staff_id": staff.id).
        where("reservations.shop_id != ?", shop.id).
        where("reservations.start_time > ? and reservations.end_time <= ?", beginning_of_day, end_of_day).exists?

      if other_shop_reservation_exist
        errors.add(:staff_ids, :other_shop, staff_name: staff.name)
      end
    end

    def validate_same_shop_overlap_reservations(staff)
      overlap_reservations_exist = ReservationStaff.joins(reservation: :menu).
        where.not(reservation_id: reservation_id.presence).
        where("reservation_staffs.staff_id": staff.id).
        where("reservations.shop_id = ?", shop.id).
        where("(reservations.start_time < (TIMESTAMP ? + (INTERVAL '1 min' * menus.interval)) and reservations.ready_time > ?)", end_time, start_time).exists?

      if overlap_reservations_exist
        errors.add(:staff_ids, :overlap_reservations, staff_name: staff.name)
      end
    end

    def validate_staff_ability(staff)
      staff_menu_ids = staff.staff_menus.pluck(:menu_id)

      menus.each do |menu|
        if staff_menu_ids.exclude?(menu.id)
          errors.add(:staff_ids, :incapacity_menu, staff_name: staff.name, menu_name: menu.name)
        end
      end
    end
  end
end

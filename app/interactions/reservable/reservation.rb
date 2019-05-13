module Reservable
  class Reservation < ActiveInteraction::Base
    include SharedMethods

    object :shop
    date :date
    object :business_time_range, class: Range, default: nil
    array :menu_ids, default: nil
    integer :booking_option_id, default: nil
    array :staff_ids, default: nil
    integer :reservation_id, default: nil
    integer :number_of_customer, default: 1

    def execute
      time_outcome = Reservable::Time.run(shop: shop, date: date)
      shop_start_at = time_outcome.result.first
      shop_close_at = time_outcome.result.last
      reservation_start_at = business_time_range.first
      reservation_end_at = business_time_range.last

      if time_outcome.invalid?
        errors.merge!(time_outcome.errors)
      end

      return if (menu_ids.blank? && booking_option_id.nil?) || business_time_range.blank?

      # validate_time_range
      if time_outcome.valid? && (
          reservation_start_at < shop_start_at ||
          reservation_end_at > shop_close_at ||
          reservation_start_at > reservation_end_at
      )
        errors.add(:business_time_range, :invalid_time_range)
      end

      if new_reseravtion_time_interval < services_required_timee
        errors.add(:menu_ids, :time_not_enough)
      end

      validate_interval_time
      validate_menu_schedules
      validate_seats_for_customers

      return if staff_ids.blank?

      working_day_staff_ids = working_day_staffs.map(&:id)
      staffs.includes(:staff_menus).each do |staff|
        if working_day_staff_ids.exclude?(staff.id)
          if closed_custom_schedules_staff_ids.include?(staff.id)
            errors.add(:staff_ids, :ask_for_leave)
            errors.add(:ask_for_leave, staff.id.to_s)
          elsif staff.freelancer?(shop)
            errors.add(:staff_ids, :freelancer)
            errors.add(:freelancer, staff.id.to_s)
          else
            errors.add(:staff_ids, :unworking_staff)
            errors.add(:unworking_staff, staff.id.to_s)
          end
        end

        validate_staffs_ability_for_customers(staff)
        validate_other_shop_reservation(staff)
        validate_same_shop_overlap_reservations(staff)
        validate_staff_ability(staff)
      end

      menus.sum(:min_staffs_number).times do |i|
        validate_lack_overlap_staff(staff_ids[i], i)
      end
    end

    private

    def total_menus_taking_time
      services_required_timee + interval_time
    end

    def services_required_timee
      if booking_option_id
        booking_option.minutes.minutes
      else
        menus.sum(:minutes).minutes
      end
    end

    def interval_time
      if booking_option_id
        booking_option.interval.minutes
      else
        menus.last.interval.minutes
      end
    end

    def booking_option
      @booking_option ||= shop.user.booking_options.find_by(id: booking_option_id)
    end

    def menus
      @menus ||= shop.menus.where(id: menu_ids)
    end

    def staffs
      @staffs ||= shop.staffs.where(id: staff_ids)
    end

    def validate_time_range
    end

    def validate_interval_time
      # The interval time should be after reservation, so we just need to any reservation overlap start time.
      previous_reservation_validation_start_time = start_time
      previous_reservation_validation_end_time = start_time

      if previous_reservation_overlap = ReservationStaff.overlap_reservations(staff_ids: staff_ids,
                                            reservation_id: reservation_id,
                                            start_time: previous_reservation_validation_start_time,
                                            end_time: previous_reservation_validation_end_time).
                                            where.not("reservations.aasm_state": "canceled").
                                            where("reservations.deleted_at": nil).
                                            where("reservations.shop_id = ?", shop.id).exists?
        errors.add(:business_time_range, "previous_reservation_interval_overlap")
      end

      # When the start time is the same, it will be counts as overlap reservation in this case.
      next_reservation_validation_start_time = end_time.advance(minutes: -1)
      next_reservation_validation_end_time = end_time.advance(seconds: interval_time)

      if next_reservation_overlap = ReservationStaff.overlap_reservations(staff_ids: staff_ids,
                                            reservation_id: reservation_id,
                                            start_time: next_reservation_validation_start_time,
                                            end_time: next_reservation_validation_end_time).
                                            where.not("reservations.aasm_state": "canceled").
                                            where("reservations.deleted_at": nil).
                                            where("reservations.shop_id = ?", shop.id).exists?
        errors.add(:business_time_range, "next_reservation_interval_overlap")
      end

      if previous_reservation_overlap || next_reservation_overlap
        errors.add(:business_time_range, :interval_too_short)
      end
    end

    def validate_menu_schedules
      menus.each do |menu|
        unless Menu.workable_scoped(shop: shop, start_time: start_time, end_time: end_time).where(id: menu.id).exists?
          errors.add(:menu_ids, :unschedule_menu)
        end

        if menu.menu_reservation_setting_rule
          if menu.menu_reservation_setting_rule.start_date > date
            errors.add(:menu_ids, :start_yet,
                       start_at: menu.menu_reservation_setting_rule.start_date.to_s)
          end

          if (menu.menu_reservation_setting_rule.end_date && menu.menu_reservation_setting_rule.end_date < date) ||
            (menu.menu_reservation_setting_rule.repeating? && ShopMenuRepeatingDate.where(shop: shop, menu: menu).first.end_date < date)
            errors.add(:menu_ids, :is_over)
          end
        end
      end
    end

    def validate_seats_for_customers
      shop_menus = shop.shop_menus.where(menu_id: menu_ids).to_a

      menus.each do |menu|
        if number_of_customer > shop_menus.find { |shop_menu| shop_menu.menu_id == menu.id }.max_seat_number
          errors.add(:menu_ids, :not_enough_seat)
        end
      end
    end

    def validate_staffs_ability_for_customers(staff)
      staff_menus = StaffMenu.where(staff_id: staff.id, menu_id: menu_ids)

      menus.each do |menu|
        if staff_menu = staff_menus.find { |staff_menu| staff_menu.menu_id == menu.id }
          if number_of_customer > staff_menu.max_customers
            errors.add(:staff_ids, :not_enough_ability)
            errors.add(:not_enough_ability, staff.id.to_s)
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

      @working_staffs = scoped.where("business_schedules.full_time = ?", true).
        or(
          scoped.
          where("business_schedules.business_state = ? and business_schedules.day_of_week = ?", "opened", start_time.wday).
          where("(business_schedules.start_time + '#{::Time.zone.now.utc_offset} seconds'::INTERVAL)::time <= ? and
                 (business_schedules.end_time + '#{::Time.zone.now.utc_offset} seconds'::INTERVAL)::time >= ?",
                 start_time.to_s(:time), ready_time.to_s(:time))
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
        where.not("reservations.aasm_state": "canceled").
        where("reservations.deleted_at": nil).
        where("reservation_staffs.staff_id": staff.id).
        where("reservations.shop_id != ?", shop.id).
        where("reservations.start_time > ? and reservations.end_time <= ?", beginning_of_day, end_of_day).exists?

      if other_shop_reservation_exist
        errors.add(:staff_ids, :other_shop)
        errors.add(:other_shop, staff.id.to_s)
      end
    end

    def validate_same_shop_overlap_reservations(staff)
      overlap_reservations_exist = menus.any? do |menu|
        ReservationStaff.joins(reservation: :menu).
          where.not(reservation_id: reservation_id.presence).
          where.not("reservations.aasm_state": "canceled").
          where("reservations.deleted_at": nil).
          where("reservation_staffs.staff_id": staff.id).
          where("reservations.shop_id = ?", shop.id).
          where("reservations.start_time < ? and reservations.end_time > ?", end_time, start_time).exists?
      end

      if overlap_reservations_exist
        errors.add(:staff_ids, :overlap_reservations)
        errors.add(:overlap_reservations, staff.id.to_s)
      end
    end

    def validate_staff_ability(staff)
      staff_menu_ids = staff.staff_menus.pluck(:menu_id)

      menus.each do |menu|
        if staff_menu_ids.exclude?(menu.id)
          errors.add(:staff_ids, :incapacity_menu)
          errors.add(:incapacity_menu, staff.id.to_s)
        end
      end
    end

    def validate_lack_overlap_staff(staff_id, index)
      first_staff_index = staff_ids.index { |_staff_id| _staff_id == staff_id }

      if first_staff_index != index
        errors.add(:staff_ids, :lack_overlap_staffs)
        errors.add(:lack_overlap_staffs, "staff-position-#{index}")
      end
    end
  end
end

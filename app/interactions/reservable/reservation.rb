module Reservable
  class Reservation < ActiveInteraction::Base
    include SharedMethods

    object :shop
    date :date
    object :business_time_range, class: Range, default: nil
    integer :menu_id, default: nil
    integer :booking_option_id, default: nil
    array :staff_ids, default: nil
    integer :reservation_id, default: nil
    integer :number_of_customer, default: 1
    boolean :overlap_restriction, default: true
    boolean :skip_before_interval_time_validation, default: false
    boolean :skip_after_interval_time_validation, default: false

    def execute
      time_outcome = Reservable::Time.run(shop: shop, date: date)

      if time_outcome.invalid?
        time_outcome.errors.details.each do |error_attr, time_errors|
          time_errors.each do |error_hash|
            errors.add(error_attr, error_hash.values.first)
          end
        end
      end

      return if (menu_id.nil? && booking_option_id.nil?) || business_time_range.blank?

      # validate_time_range
      if time_outcome.valid?
        shop_start_at = time_outcome.result.first
        shop_close_at = time_outcome.result.last
        reservation_start_at = business_time_range.first
        reservation_end_at = business_time_range.last

        if reservation_start_at < shop_start_at ||
            reservation_end_at > shop_close_at ||
            reservation_start_at > reservation_end_at
          errors.add(:business_time_range, :invalid_time_range)
        end
      end

      if new_reseravtion_time_interval < services_required_time
        errors.add(:menu_id, :time_not_enough)
      end

      validate_interval_time if overlap_restriction
      validate_menu_schedules
      validate_seats_for_customers

      return if staff_ids.blank?
      validate_shop_capability_for_customers

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
        validate_same_shop_overlap_reservations(staff) if overlap_restriction
        validate_staff_ability(staff)
      end

      menu.min_staffs_number.times do |i|
        validate_lack_overlap_staff(staff_ids[i], i)
      end
    end

    private

    def services_required_time
      if booking_option_id
        booking_option.booking_option_menus.find_by(menu_id: menu_id).required_time.minutes
      else
        menu.minutes.minutes
      end
    end

    def interval_time
      if booking_option_id
        booking_option.interval.minutes
      else
        menu.interval.minutes
      end
    end

    def booking_option
      @booking_option ||= shop.user.booking_options.find_by(id: booking_option_id)
    end

    def menu
      @menu ||= shop.menus.find(menu_id)
    end

    def staffs
      @staffs ||= shop.staffs.where(id: staff_ids)
    end

    def validate_before_interval_time
      # The interval time should be after reservation, so we just need to any reservation overlap start time.
      previous_reservation_validation_start_time = start_time
      previous_reservation_validation_end_time = start_time

      # The interval time is not enough for previous reservation
      if @previous_reservation_overlap =
          ReservationStaff.overlap_reservations(
            staff_ids: staff_ids,
            reservation_id: reservation_id,
            start_time: previous_reservation_validation_start_time,
            end_time: previous_reservation_validation_end_time).
            where("reservations.shop_id = ?", shop.id).exists?
        errors.add(:business_time_range, "previous_reservation_interval_overlap")
      end

      unless @previous_reservation_overlap
        previous_reservation_validation_start_time = start_time.advance(seconds: -interval_time)
        previous_reservation_validation_end_time = start_time.advance(seconds: -interval_time)

        # The interval time is enough for previous reservation but not enough for current reservation
        if @previous_reservation_overlap =
            ReservationStaff.
            overlap_reservations_scope(staff_ids: staff_ids, reservation_id: reservation_id).
            where("reservations.shop_id = ?", shop.id).
            where("reservation_staffs.work_start_at < ? and reservation_staffs.work_end_at > ?",
                  previous_reservation_validation_end_time, previous_reservation_validation_start_time).exists?
          errors.add(:business_time_range, "previous_reservation_interval_overlap")
        end
      end
    end

    def validate_after_interval_time
      next_reservation_validation_start_time = end_time
      next_reservation_validation_end_time = end_time.advance(seconds: interval_time)

      # The interval time is not enough for current reservation
      if @next_reservation_overlap =
          ReservationStaff.overlap_reservations(
            staff_ids: staff_ids,
            reservation_id: reservation_id,
            start_time: next_reservation_validation_start_time,
            end_time: next_reservation_validation_end_time).where("reservations.shop_id = ?", shop.id).exists?
      errors.add(:business_time_range, "next_reservation_interval_overlap")
      end

      # The interval time is enough for current reservation, but not enough for next reservation
      unless @next_reservation_overlap
        next_reservation_validation_start_time = end_time
        next_reservation_validation_end_time = end_time

        if @next_reservation_overlap =
            ReservationStaff.
            overlap_reservations_scope(staff_ids: staff_ids, reservation_id: reservation_id).
            where("reservations.shop_id = ?", shop.id).
            where("reservation_staffs.prepare_time < ? and reservation_staffs.work_end_at > ?",
                  next_reservation_validation_end_time, next_reservation_validation_start_time).exists?
          errors.add(:business_time_range, "next_reservation_interval_overlap")
        end
      end
    end

    def validate_interval_time
      validate_before_interval_time unless skip_before_interval_time_validation
      validate_after_interval_time unless skip_after_interval_time_validation

      if (!skip_before_interval_time_validation || !skip_after_interval_time_validation) &&
          (@previous_reservation_overlap || @next_reservation_overlap)
        errors.add(:business_time_range, :interval_too_short)
      end
    end

    def validate_menu_schedules
      unless Menu.workable_scoped(shop: shop, start_time: start_time, end_time: end_time).where(id: menu.id).exists?
        errors.add(:menu_id, :unschedule_menu)
      end

      if menu.menu_reservation_setting_rule
        if menu.menu_reservation_setting_rule.start_date > date
          errors.add(:menu_id, :start_yet,
                     start_at: menu.menu_reservation_setting_rule.start_date.to_s)
        end

        if (menu.menu_reservation_setting_rule.end_date && menu.menu_reservation_setting_rule.end_date < date) ||
            (menu.menu_reservation_setting_rule.repeating? && ShopMenuRepeatingDate.where(shop: shop, menu: menu).first.end_date < date)
          errors.add(:menu_id, :is_over)
        end
      end
    end

    def validate_seats_for_customers
      if number_of_customer > shop_menu.max_seat_number
        errors.add(:menu_id, :not_enough_seat)
      end
    end

    def validate_staffs_ability_for_customers(staff)
      staff_menus = StaffMenu.where(staff_id: staff.id, menu_id: menu_id)

      if staff_menu = staff_menus.find { |staff_menu| staff_menu.menu_id == menu.id }
        if number_of_customer > staff_menu.max_customers
          errors.add(:staff_ids, :not_enough_ability)
          errors.add(:not_enough_ability, staff.id.to_s)
        end
      end
    end

    # validate does the number of customers using the menu over the shop/staff capabiliy
    def validate_shop_capability_for_customers
      shop_max_seat_number = shop_menu&.max_seat_number || 1

      # XXX: when no staffs could handle this menu, staff_max_customers is 0
      staff_max_customers = StaffMenu.where(staff_id: staff_ids, menu_id: menu_id).where.not(max_customers: nil).minimum(:max_customers) || 0

      min_shop_customer_capability = [shop_max_seat_number, staff_max_customers].min

      existing_customers = ::Reservation.
        left_outer_joins(:menus).
        where.not(id: reservation_id.presence).
        where.not("reservations.aasm_state": "canceled").
        where.not("menus.min_staffs_number": 0).
        where("reservation_menus.menu_id": menu_id).
        where("reservations.deleted_at": nil).
        where("reservations.shop_id = ?", shop.id).
        where("reservations.start_time < ? and reservations.end_time > ?", end_time, start_time).
        group("reservations.id").
        sum(&:count_of_customers)

      if min_shop_customer_capability < existing_customers + number_of_customer
        errors.add(:menu_id, :shop_or_staff_not_enough_ability)
        errors.add(:shop_or_staff_not_enough_ability, menu_id)
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
      other_shop_reservation_exist = ReservationStaff.
        overlap_reservations_scope(staff_ids: staff.id, reservation_id: reservation_id).
        where("reservations.shop_id != ?", shop.id).
        where("reservation_staffs.work_start_at > ? and reservation_staffs.work_end_at < ?", beginning_of_day, end_of_day).exists?

      if other_shop_reservation_exist
        errors.add(:staff_ids, :other_shop)
        errors.add(:other_shop, staff.id.to_s)
      end
    end

    def validate_same_shop_overlap_reservations(staff)
      overlap_reservations_exist = ReservationStaff.
        overlap_reservations_scope(staff_ids: staff.id, reservation_id: reservation_id).
        where("reservations.shop_id = ?", shop.id).
        where("reservation_staffs.work_start_at < ? and reservation_staffs.work_end_at > ?", end_time, start_time).exists?

      if overlap_reservations_exist
        errors.add(:staff_ids, :overlap_reservations)
        errors.add(:overlap_reservations, staff.id.to_s)
      end
    end

    def validate_staff_ability(staff)
      staff_menu_ids = staff.staff_menus.pluck(:menu_id)

      if staff_menu_ids.exclude?(menu.id)
        errors.add(:staff_ids, :incapacity_menu)
        errors.add(:incapacity_menu, staff.id.to_s)
      end
    end

    def validate_lack_overlap_staff(staff_id, index)
      first_staff_index = staff_ids.index { |_staff_id| _staff_id == staff_id }

      if first_staff_index != index
        errors.add(:staff_ids, :lack_overlap_staffs)
        errors.add(:lack_overlap_staffs, "staff-position-#{index}")
      end
    end

    def shop_menu
      @shop_menu ||= shop.shop_menus.find_by(menu_id: menu_id)
    end
  end
end

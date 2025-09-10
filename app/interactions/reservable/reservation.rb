# frozen_string_literal: true

# validate single booking option booking, it validates, shop menu capacity and staff ability
# [Redudent]
module Reservable
  class Reservation < ActiveInteraction::Base
    include SharedMethods

    object :shop
    date :date
    time :start_time, default: nil
    time :end_time, default: nil
    integer :menu_id, default: nil
    integer :menu_required_time, default: nil
    integer :total_require_time, default: nil
    array :staff_ids, default: nil
    integer :reservation_id, default: nil
    integer :number_of_customer, default: 1
    boolean :overlap_restriction, default: true
    boolean :overbooking_restriction, default: true
    boolean :skip_before_interval_time_validation, default: false
    boolean :skip_after_interval_time_validation, default: false
    boolean :online_reservation, default: false
    object :booking_page, default: nil

    def execute
      time_outcome = Reservable::Time.run(shop: shop, booking_page: booking_page, date: date)

      if time_outcome.invalid?
        time_outcome.errors.details.each do |error_attr, time_errors|
          time_errors.each do |error_hash|
            # errors.add(:date, :shop_closed)
            errors.add(error_attr, error_hash.values.first)
          end
        end
      end

      return if start_time.blank? || end_time.blank?

      # validate_time_range
      if time_outcome.valid?
        shop_start_at = time_outcome.result.first.first
        shop_close_at = time_outcome.result.last.last

        if (time_outcome.result.none? { |working_time_range| start_time >= working_time_range.first && end_time <= working_time_range.last })
          if start_time < shop_start_at
            errors.add(:start_time, :invalid_time)
          else
            errors.add(:end_time, :invalid_time)
          end
        end

        if start_time > end_time
          errors.add(:end_time, :invalid_time)
        end

        if date.today? && booking_page && booking_page.booking_limit_day == 0 && start_time < ::Time.current.advance(hours: booking_page.booking_limit_hours)
          errors.add(:start_time, :invalid_time)
        end
      end

      # XXX: menu is required for the below validation
      return if (menu_id.nil? || menu_required_time.nil?) && total_require_time.nil?

      # TODO: [Multiple booking option] check total menu require time once
      if menu_required_time < menu.minutes
        errors.add(:menu_id, :time_not_enough, menu_id: menu_id)
      end

      validate_booking_events
      validate_activity_reservation
      validate_interval_time if validate_overlap?
      # validate_menu_schedules
      validate_seats_for_customers if overbooking_restriction
      validate_required_staffs

      return if staff_ids.blank?

      validate_shop_capability_for_customers if overbooking_restriction

      working_day_staff_ids = working_day_staffs.map(&:id)
      staffs.includes(:staff_menus, staff_account: :user).each do |staff|
        if working_day_staff_ids.exclude?(staff.id)
          if staff.freelancer?(shop)
            errors.add(:staff_ids, :freelancer, staff_id: staff.id, menu_id: menu_id)
          else
            # XXX: part time but had business schedule
            errors.add(:staff_ids, :unworking_staff, staff_id: staff.id, menu_id: menu_id)
          end
        end

        # validate personal schedule
        if closed_custom_schedules_staff_ids.include?(staff.id)
          errors.add(:staff_ids, :ask_for_leave, staff_id: staff.id, menu_id: menu_id)
        end

        validate_staffs_ability_for_customers(staff) if overbooking_restriction
        validate_other_shop_reservation(staff)
        validate_same_shop_overlap_reservations(staff) if validate_overlap?
        validate_staff_ability(staff)
      end
    end

    private

    def interval_time
      menu.interval.minutes
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
        errors.add(:start_time, :interval_too_short)
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
          errors.add(:start_time, :interval_too_short)
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
            end_time: next_reservation_validation_end_time
          )
          .where("reservations.shop_id = ?", shop.id).exists?
        errors.add(:end_time, :interval_too_short)
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
          errors.add(:end_time, :interval_too_short)
        end
      end
    end

    # Same booking time
    # IF there is other event booking page
    #   If the current booking page is event booking page and the the same special date
    #     valid, still allow to book
    #   ELSE
    #     invalid
    # ELSE
    #   valid
    def validate_booking_events
      if booking_page
        related_staff_ids = Staff.where(id: staff_ids).map {|staff| staff.related_staffs&.map(&:id) }.flatten.compact
        shop_ids = ShopStaff.where(staff_id: related_staff_ids).pluck(:shop_id).uniq
        event_booking_page_ids = BookingPage.active.started.where(shop_id: shop_ids, event_booking: true).pluck(:id).presence
        event_booking_page_ids ||= BookingPage.active.started.where(shop: shop, event_booking: true).pluck(:id)
        scope = BookingPageSpecialDate.where(booking_page_id: event_booking_page_ids)
        overlap_special_date_booking_page_ids = scope.where("start_at < ? and end_at > ?", end_time, start_time).distinct.pluck(:booking_page_id)
        if overlap_special_date_booking_page_ids.exclude?(booking_page.id) && overlap_special_date_booking_page_ids.present?
          errors.add(:booking_page, :overlap_event_booking, overlap_special_date_booking_page_ids: overlap_special_date_booking_page_ids)
        end
      end
    end

    def validate_activity_reservation
      if shop.user.reservations.where(deleted_at: nil).where.not(survey_activity_id: nil).where.not(aasm_state: "canceled").where("start_time < ? and end_time > ?", end_time, start_time).exists?
        errors.add(:shop, :overlap_activity_reservation)
      end
    end

    def validate_interval_time
      validate_before_interval_time unless skip_before_interval_time_validation
      validate_after_interval_time unless skip_after_interval_time_validation
    end

    # def validate_menu_schedules
    #   unless Menu.workable_scoped(shop: shop, start_time: start_time, end_time: end_time).where(id: menu.id).exists?
    #     errors.add(:menu_id, :unschedule_menu, menu_id: menu_id)
    #   end
    #
    #   if menu.menu_reservation_setting_rule
    #     if menu.menu_reservation_setting_rule.start_date > date
    #       errors.add(:menu_id, :start_yet,
    #                  start_at: I18n.l(menu.menu_reservation_setting_rule.start_date, format: :year_month_date), menu_id: menu_id)
    #     end
    #
    #     if (menu.menu_reservation_setting_rule.end_date && menu.menu_reservation_setting_rule.end_date < date) ||
    #         (menu.menu_reservation_setting_rule.repeating? && ShopMenuRepeatingDate.where(shop: shop, menu: menu).first.end_date < date)
    #       errors.add(:menu_id, :is_over, menu_id: menu_id)
    #     end
    #   end
    # end

    def validate_seats_for_customers
      if number_of_customer > shop_menu.max_seat_number
        errors.add(:menu_id, :not_enough_seat, menu_id: menu_id)
      end
    end

    def validate_staffs_ability_for_customers(staff)
      if staff_menu = staff.staff_menus.find { |staff_menu| staff_menu.menu_id == menu_id }
        if number_of_customer > staff_menu.max_customers
          errors.add(:staff_ids, :not_enough_ability, staff_id: staff.id, menu_id: menu_id)
        end
      end
    end

    # validate does the number of customers using the menu over the shop/staff capabiliy
    def validate_shop_capability_for_customers
      min_shop_customer_capability = compose(Reservable::CalculateCapabilityForCustomers, shop: shop, menu_id: menu_id, staff_ids: staff_ids)

      existing_customers = ::Reservation.
        left_outer_joins(:menus).
        where.not(id: reservation_id.presence).
        where.not("reservations.aasm_state": "canceled").
        where("reservation_menus.menu_id": menu_id).
        where("reservations.deleted_at": nil).
        where("reservations.shop_id = ?", shop.id).
        where("reservations.start_time < ? and reservations.end_time > ?", end_time, start_time).
        group("reservations.id").
        sum(&:count_of_customers)

      if min_shop_customer_capability < existing_customers + number_of_customer
        errors.add(:menu_id, :shop_or_staff_not_enough_ability, menu_id: menu_id)
      end
    end

    def working_day_staffs
      return @working_staffs if defined?(@working_staffs)

      scoped = staffs.
        joins("LEFT OUTER JOIN business_schedules ON business_schedules.staff_id = staffs.id AND business_schedules.shop_id = #{shop.id}
               LEFT OUTER JOIN custom_schedules opened_custom_schedules ON opened_custom_schedules.staff_id = staffs.id AND
                                                                           opened_custom_schedules.shop_id = #{shop.id} AND
                                                                           opened_custom_schedules.open = true
              ")

      @working_staffs = scoped.where("business_schedules.full_time = ?", true).
        or(
          scoped.
          where("business_schedules.business_state = ? and business_schedules.day_of_week = ?", "opened", start_time.wday).
          where("(business_schedules.start_time + '#{::Time.zone.now.utc_offset} seconds'::INTERVAL)::time <= ? and
                 (business_schedules.end_time + '#{::Time.zone.now.utc_offset} seconds'::INTERVAL)::time >= ?",
                 start_time.to_fs(:time), ready_time.to_fs(:time))
        ).
        or(
          scoped.
          where("opened_custom_schedules.start_time <= ? and opened_custom_schedules.end_time >= ?", start_time, ready_time)
        ).to_a
    end

    def ready_time
      @ready_time ||= end_time
    end

    def validate_other_shop_reservation(staff)
      # all the staffs connected with this user
      related_staff_ids = staff.related_staffs&.map(&:id) || staff.id

      scope = ReservationStaff.
        overlap_reservations_scope(staff_ids: related_staff_ids, reservation_id: reservation_id).
        where("reservations.shop_id != ?", shop.id)

      other_shop_reservation_exist =
        if online_reservation
          scope.where("reservation_staffs.work_start_at < ? and reservation_staffs.work_end_at > ?", end_time, start_time).exists?
        else
          scope.where("reservation_staffs.work_start_at > ? and reservation_staffs.work_end_at < ?", beginning_of_day, end_of_day).exists?
        end

      if other_shop_reservation_exist
        errors.add(:staff_ids, :other_shop, staff_id: staff.id, menu_id: menu_id)
      end
    end

    def validate_same_shop_overlap_reservations(staff)
      overlap_reservations = ReservationStaff.
        overlap_reservations_scope(staff_ids: staff.id, reservation_id: reservation_id).
        where("reservations.shop_id = ?", shop.id).
        where("reservation_staffs.work_start_at < ? and reservation_staffs.work_end_at > ?", end_time, start_time)

      # overlap reservation with different menu, it is fine for the same reservation with the same menu
      if ReservationMenu.where(reservation_id: overlap_reservations.pluck(:reservation_id)).where.not(menu_id: menu_id).exists?
        errors.add(:staff_ids, :overlap_reservations, staff_id: staff.id, menu_id: menu_id)
      end
    end

    def validate_staff_ability(staff)
      staff_menu_ids = staff.staff_menus.pluck(:menu_id)

      if staff_menu_ids.exclude?(menu.id)
        errors.add(:staff_ids, :incapacity_menu, staff_id: staff.id, menu_id: menu_id)
      end
    end

    def validate_required_staffs
      if Array.wrap(staff_ids).uniq.size < menu.min_staffs_number
        errors.add(:menu_id, :lack_staffs, menu_id: menu_id)
      end
    end

    def validate_overlap?
      overlap_restriction && !menu.no_manpower?
    end

    def shop_menu
      @shop_menu ||= shop.shop_menus.find_by!(menu_id: menu_id)
    end
  end
end

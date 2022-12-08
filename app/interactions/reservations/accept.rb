# frozen_string_literal: true

module Reservations
  class Accept < ActiveInteraction::Base
    object :current_staff, class: Staff
    object :reservation

    validate :validate_staff

    def execute
      reservation.transaction do
        reservation_for_staff.accepted!
        reservation.reservation_customers.pending.each do |reservation_customer|
          compose(
            ReservationCustomers::Accept,
            reservation_id: reservation_customer.reservation_id,
            customer_id: reservation_customer.customer_id,
            current_staff: current_staff
          )
        end
        reservation.try_accept
        reservation.save!

        if !has_valid_working_schedule?
          # If staff doesn't have proper working time(ignore off schedule) create a custom schedule for them
          current_staff.custom_schedules.create!(
            shop: shop,
            open: true,
            start_time: reservation.start_time,
            end_time: reservation.ready_time
          )
        end

        reservation
      end
    end

    private

    def validate_staff
      errors.add(:current_staff, :who_r_u) unless reservation_for_staff
    end

    def reservation_for_staff
      @reservation_for_staff ||= reservation.for_staff(current_staff)
    end

    def shop
      @shop ||= reservation.shop
    end

    def has_valid_working_schedule?
      return @valid_working_schedule if defined?(@valid_working_schedule)

      start_time = reservation.start_time
      ready_time = reservation.ready_time

      scoped = Staff.where(id: current_staff.id).
        joins("LEFT OUTER JOIN business_schedules ON business_schedules.staff_id = staffs.id AND business_schedules.shop_id = #{shop.id}
               LEFT OUTER JOIN custom_schedules opened_custom_schedules ON opened_custom_schedules.staff_id = staffs.id AND
                                                                           opened_custom_schedules.shop_id = #{shop.id} AND
                                                                           opened_custom_schedules.open = true
              ")

      @valid_working_schedule = scoped.where("business_schedules.full_time = ?", true).
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
        ).to_a.present?
    end
  end
end

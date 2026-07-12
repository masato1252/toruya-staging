# frozen_string_literal: true

module SchedulesHelper
  extend ActiveSupport::Concern

  included do
    helper_method :reservation_popup_path if respond_to?(:helper_method)
  end

  def reservation_popup_path(reservation)
    return nil unless reservation

    if reservation.is_a?(Reservation)
      lines_user_bot_shop_reservation_path(reservation.user_id, reservation.shop, reservation)
    else
      row = reservation.respond_to?(:to_h) ? reservation.to_h : reservation
      row = row.with_indifferent_access if row.respond_to?(:with_indifferent_access)
      lines_user_bot_shop_reservation_path(
        row[:user_id].presence || business_owner_id,
        row[:shop].presence || row[:shop_id],
        row[:id]
      )
    end
  end

  private

  def schedules_events(schedules)
    @schedules = (schedules[:reservations] + schedules[:booking_page_holder_schedules] + schedules[:off_schedules] + schedules[:open_schedules]).each_with_object([]) do |schedule, schedules|
      if schedule.is_a?(Reservation)
        schedules << ReservationSerializer.new(schedule).attributes_hash
      elsif schedule.is_a?(BookingPageSpecialDate)
        schedules << BookingPageSpecialDateSerializer.new(schedule).attributes_hash
      else
        schedules << OffScheduleSerializer.new(schedule).attributes_hash
      end
    end.sort_by! { |option| option[:time] }
  end
end

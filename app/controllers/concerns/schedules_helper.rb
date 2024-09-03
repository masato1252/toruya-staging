module SchedulesHelper
  extend ActiveSupport::Concern

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
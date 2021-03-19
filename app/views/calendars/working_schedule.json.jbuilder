# frozen_string_literal: true

if @schedules
  json.working_dates @schedules[:working_dates]
  json.holiday_dates @schedules[:holiday_dates]
else
  json.working_dates []
  json.holiday_dates []
end

json.reservation_dates @reservation_dates ? @reservation_dates.map(&:to_s) : []
json.available_booking_dates @available_booking_dates || []
json.personal_schedule_dates @personal_schedule_dates&.map(&:to_s)

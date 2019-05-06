if @schedules
  json.working_dates @schedules[:working_dates]
  json.holiday_dates @schedules[:holiday_dates]
else
  json.working_dates []
  json.holiday_dates []
end

json.reservation_dates @reservation_dates ? @reservation_dates.map(&:to_s) : []

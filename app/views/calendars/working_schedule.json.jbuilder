json.holiday_days @working_dates[:holidays].map(&:day)
json.full_time @working_dates[:full_time]
json.shop_working_wdays @working_dates[:shop_working_wdays]
json.shop_working_on_holiday @working_dates[:shop_working_on_holiday]
json.staff_working_wdays @working_dates[:staff_working_wdays]
json.working_days @working_dates[:working_dates].map(&:day)
json.off_days @working_dates[:off_dates].map(&:day)
json.reservation_days @reservation_dates.map(&:day)

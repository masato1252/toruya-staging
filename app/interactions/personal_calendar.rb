class PersonalCalendar < ActiveInteraction::Base
  array :working_shop_options
  date :date

  def execute
    working_dates = {
      full_time: false,
      holiday_working: false,
      shop_working_wdays: [],
      staff_working_wdays: [],
      working_dates: [],
      off_dates: [],
      holidays: []
    }

    working_shop_options.each do |option|
      shop = option.shop
      staff = option.staff

      staff_working_dates = Staffs::WorkingDates.run!(shop: shop, staff: staff, date_range: date.beginning_of_month..date.end_of_month)

      working_dates[:full_time] = working_dates[:full_time] || staff_working_dates[:full_time]
      working_dates[:holiday_working] = working_dates[:holiday_working] || staff_working_dates[:holiday_working]
      working_dates[:shop_working_wdays] = (working_dates[:shop_working_wdays] + staff_working_dates[:shop_working_wdays]).uniq
      working_dates[:staff_working_wdays] = (working_dates[:staff_working_wdays] + staff_working_dates[:staff_working_wdays]).uniq
      working_dates[:working_dates] = (working_dates[:working_dates] + staff_working_dates[:working_dates]).uniq
      working_dates[:off_dates] = (working_dates[:off_dates] + staff_working_dates[:off_dates]).uniq
      working_dates[:holidays] = (working_dates[:holidays] + staff_working_dates[:holidays]).uniq
    end

    reservation_dates = []
    working_shop_options.map(&:shop).each do |shop|
      reservation_dates += Shops::ReservationDates.run!(shop: shop, date_range: date.beginning_of_month..date.end_of_month)
    end

    return [working_dates, reservation_dates]
  end
end

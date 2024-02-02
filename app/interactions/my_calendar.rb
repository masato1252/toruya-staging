# frozen_string_literal: true

class MyCalendar < ActiveInteraction::Base
  object :social_user
  array :working_shop_options
  array :all_shop_ids
  date :date

  def execute
    working_dates = {
      full_time: false,
      holiday_working: false,
      shop_working_wdays: [],
      staff_working_wdays: [],
      working_dates: [],
      off_dates: [],
      holidays: [],
    }

    working_shop_options.each do |option|
      shop = option.shop
      staff = option.staff

      staff_working_dates = Staffs::WorkingDateRules.run!(shop: shop, staff: staff, date_range: date_range)

      working_dates[:full_time] = working_dates[:full_time] || staff_working_dates[:full_time]
      working_dates[:holiday_working] = working_dates[:holiday_working] || staff_working_dates[:holiday_working]
      working_dates[:shop_working_wdays] = (working_dates[:shop_working_wdays] + staff_working_dates[:shop_working_wdays]).uniq
      working_dates[:staff_working_wdays] = (working_dates[:staff_working_wdays] + staff_working_dates[:staff_working_wdays]).uniq
      working_dates[:working_dates] = (working_dates[:working_dates] + staff_working_dates[:working_dates]).uniq
      working_dates[:off_dates] = (working_dates[:off_dates] + staff_working_dates[:off_dates]).uniq
      working_dates[:holidays] = (working_dates[:holidays] + staff_working_dates[:holidays]).uniq
    end


    # reservation_dates += Staffs::ReservationDates.run!(user: user, all_shop_ids: all_shop_ids, date_range: date_range)
    reservation_ids = ReservationStaff.joins(:reservation).where(staff_id: social_user.staffs.map(&:id)).merge(Reservation.uncanceled.where("reservations.start_time" => date_range)).pluck(:reservation_id)
    reservation_dates = Reservation.where(id: reservation_ids).pluck(:start_time).map { |start_time| start_time.to_date }

    return [
      compose(CalendarSchedules::Create, rules: working_dates, date_range: date_range),
      reservation_dates.uniq,
      CustomSchedule.where(user: social_user.current_users).where(start_time: date_range).map(&:dates).flatten.uniq
    ]
  end

  private

  def beginning_of_month
    @beginning_of_month ||= date.beginning_of_month.beginning_of_day
  end

  def end_of_month
    @end_of_month ||= date.end_of_month.end_of_day
  end

  def date_range
    @date_range ||= beginning_of_month..end_of_month
  end
end

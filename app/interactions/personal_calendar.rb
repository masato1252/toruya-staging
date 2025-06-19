# frozen_string_literal: true

class PersonalCalendar < ActiveInteraction::Base
  array :working_shop_options
  array :all_shop_ids
  date :date
  object :user

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

    reservation_dates = []
    working_shop_options.map(&:shop).each do |shop|
      reservation_dates += Shops::ReservationDates.run!(shop: shop, date_range: date_range)
    end

    reservation_dates += Users::ReservationDates.run!(user: user, all_shop_ids: all_shop_ids, date_range: date_range)
    event_booking_page_ids = BookingPage.where(shop_id: all_shop_ids, event_booking: true).pluck(:id)
    reservation_dates += BookingPageSpecialDate.where(booking_page_id: event_booking_page_ids).where("start_at >= ? and end_at <= ?", beginning_of_month, end_of_month).pluck(:start_at).map(&:to_date)

    return [
      compose(CalendarSchedules::Create, rules: working_dates, date_range: date_range),
      reservation_dates.uniq,
      CustomSchedule.where(start_time: date_range).where(user_id: user.all_staff_related_users.pluck(:id)).map(&:dates).flatten.uniq
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

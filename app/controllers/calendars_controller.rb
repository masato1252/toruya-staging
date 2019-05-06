class CalendarsController < DashboardController
  def working_schedule
    @working_dates = Staffs::WorkingDateRules.run!(shop: shop, staff: staff, date_range: date.beginning_of_month..date.end_of_month)
    @reservation_dates = Shops::ReservationDates.run!(shop: shop, date_range: month_dates)
    render action: :working_schedule
  end

  def personal_working_schedule
    @working_dates, @reservation_dates = PersonalCalendar.run!(user: current_user,
                                                               working_shop_options: member_shops_options,
                                                               all_shop_ids: working_shop_options(include_user_own: true).map(&:shop_id).uniq,
                                                               date: date)
    render action: :working_schedule
  end

  def booking_page_settings
    @working_dates = Booking::Calendar.run!(shop: shop, date_range: month_dates)
    render action: :working_schedule
  end

  private

  def date
    @date ||= Time.zone.parse(params[:date]).to_date
  end

  def month_dates
    date.beginning_of_month..date.end_of_month
  end
end

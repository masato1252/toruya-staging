class CalendarsController < DashboardController
  def working_schedule
    date = Time.zone.parse(params[:date]).to_date

    @working_dates = Staffs::WorkingDates.run!(shop: shop, staff: staff, date_range: date.beginning_of_month..date.end_of_month)
    @reservation_dates = Shops::ReservationDates.run!(shop: shop, date_range: date.beginning_of_month..date.end_of_month)
  end

  def personal_working_schedule
    @working_dates, @reservation_dates = PersonalCalendar.run!(working_shop_options: working_shop_options(include_user_own: true),
                                                                date: Time.zone.parse(params[:date]).to_date)
    render action: :working_schedule
  end
end

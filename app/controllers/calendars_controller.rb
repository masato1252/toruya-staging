class CalendarsController < DashboardController
  def working_schedule
    date = Time.zone.parse(params[:date]).to_date

    @working_dates = Staffs::WorkingDateRules.run!(shop: shop, staff: staff, date_range: date.beginning_of_month..date.end_of_month)
    @reservation_dates = Shops::ReservationDates.run!(shop: shop, date_range: date.beginning_of_month..date.end_of_month)
  end

  def personal_working_schedule
    @working_dates, @reservation_dates = PersonalCalendar.run!(user: current_user,
                                                               all_shop_ids: working_shop_options(include_user_own: true).map(&:shop_id).uniq,
                                                               working_shop_options: member_shops_options,
                                                               date: Time.zone.parse(params[:date]).to_date)
    render action: :working_schedule
  end
end

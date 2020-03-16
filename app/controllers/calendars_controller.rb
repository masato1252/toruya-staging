class CalendarsController < DashboardController
  def working_schedule
    @schedules = CalendarSchedules::Create.run!(
      rules: Staffs::WorkingDateRules.run!(shop: shop, staff: staff, date_range: month_dates),
      date_range: month_dates
    )
    @reservation_dates = Shops::ReservationDates.run!(shop: shop, date_range: month_dates)
    render action: :working_schedule
  end

  def personal_working_schedule
    @schedules, @reservation_dates = PersonalCalendar.run!(user: current_user,
                                                           working_shop_options: member_shops_options,
                                                           all_shop_ids: working_shop_options(include_user_own: true).map(&:shop_id).uniq,
                                                           date: date)
    render action: :working_schedule
  end

  def booking_page_settings
    shop = current_user.shops.find_by(id: params[:shop_id])
    overbooking_restriction = ActiveModel::Type::Boolean.new.cast(params[:overbooking_restriction])

    outcome = Booking::Calendar.run(
      shop: shop,
      booking_page: BookingPage.new(overbooking_restriction: overbooking_restriction),
      date_range: month_dates,
      booking_option_ids: params[:booking_option_ids],
      special_dates: ActiveModel::Type::Boolean.new.cast(params[:had_special_date]) ? params[:special_dates] : [],
      interval: params[:interval],
      overbooking_restriction: overbooking_restriction
    )

    if outcome.valid?
      @schedules, @available_booking_dates = outcome.result
    end

    render action: :working_schedule
  end

  private

  def date
    @date ||= Time.zone.parse(params[:date]).to_date
  end

  def month_dates
    date.beginning_of_month.beginning_of_day..date.end_of_month.end_of_day
  end
end

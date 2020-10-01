class Lines::UserBot::CalendarsController < Lines::UserBotDashboardController
  def personal_working_schedule
    @schedules, @reservation_dates =
      PersonalCalendar.run!(
        user: current_user,
        working_shop_options: member_shops_options,
        all_shop_ids: working_shop_options(include_user_own: true).map(&:shop_id).uniq,
        date: date
    )

    render template: "calendars/working_schedule"
  end

  private

  def date
    @date ||= Time.zone.parse(params[:date]).to_date
  end

  def month_dates
    date.beginning_of_month.beginning_of_day..date.end_of_month.end_of_day
  end
end

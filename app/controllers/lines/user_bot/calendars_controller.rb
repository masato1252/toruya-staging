# frozen_string_literal: true

class Lines::UserBot::CalendarsController < Lines::UserBotDashboardController
  def personal_working_schedule
    working_shop_ids = member_shops_options.map(&:shop_id).uniq
    all_shop_ids = working_shop_options(include_user_own: true).map(&:shop_id).uniq

    @schedules, @reservation_dates, @personal_schedule_dates =
      Rails.cache.fetch([current_user.id, working_shop_ids, all_shop_ids, date.year, date.month], expires_in: 10.minutes) do
        PersonalCalendar.run!(
          user: current_user,
          working_shop_options: member_shops_options,
          all_shop_ids: all_shop_ids,
          date: date
        )
      end

    render template: "calendars/working_schedule"
  end

  private

  def date
    @date ||= params[:date].present? ? Time.zone.parse(params[:date]).to_date : Time.zone.now.to_date
  end

  def month_dates
    date.beginning_of_month.beginning_of_day..date.end_of_month.end_of_day
  end
end

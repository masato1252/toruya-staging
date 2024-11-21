# frozen_string_literal: true

require "flow_backtracer"
class Lines::UserBot::CalendarsController < Lines::UserBotDashboardController
  def personal_working_schedule
    shop_options = working_shop_options(shops: Current.business_owner.shops)

    @schedules, @reservation_dates, @personal_schedule_dates =
      PersonalCalendar.run!(
        user: Current.business_owner,
        working_shop_options: shop_options,
        all_shop_ids: Current.business_owner.shop_ids,
        date: date
    )

    render template: "calendars/working_schedule"
  end

  def my_working_schedule
    shop_options = working_shop_options(shops: Current.social_user.shops)

    @schedules, @reservation_dates, @personal_schedule_dates =
      MyCalendar.run!(
        social_user: Current.social_user,
        working_shop_options: shop_options,
        all_shop_ids: shop_options.map(&:shop_id),
        date: date
    )

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
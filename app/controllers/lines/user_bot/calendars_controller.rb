# frozen_string_literal: true

require "flow_backtracer"
class Lines::UserBot::CalendarsController < Lines::UserBotDashboardController
  # The owner-scoped social-user URL has no useful legacy implementation.
  # Migrated owners proxy the calendar JSON to V1 before any AR association is
  # touched.
  def index
    if compat_read_data_plane?
      return render_compat_working_schedule(
        "/lines/user_bot/owner/#{compat_calendar_owner_id}/calendars/social_service_user_id/#{params[:social_service_user_id]}"
      )
    end

    head :not_found
  end

  def personal_working_schedule
    if compat_read_data_plane?
      return render_compat_working_schedule(
        "/lines/user_bot/owner/#{compat_calendar_owner_id}/calendars/personal_working_schedule"
      )
    end

    shop_options = working_shop_options(shops: Current.business_owner.shops)

    @schedules, @reservation_dates, @personal_schedule_dates =
      PersonalCalendar.run!(
        user: Current.business_owner,
        working_shop_options: shop_options,
        all_shop_ids: Current.business_owner.calendar_shop_ids,
        visible_open_schedule_user_ids: Current.social_user.current_users.pluck(:id),
        date: date
    )

    render template: "calendars/working_schedule"
  end

  def my_working_schedule
    if compat_read_data_plane?
      path =
        if params[:social_service_user_id].present?
          "/lines/user_bot/calendars/social_service_user_id/#{params[:social_service_user_id]}"
        else
          "/lines/user_bot/calendars/my_working_schedule"
        end
      return render_compat_working_schedule(path)
    end

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

  def compat_calendar_owner_id
    resolve_compat_owner_id(nil) || resolve_compat_current_user_id(nil)
  end

  def render_compat_working_schedule(path)
    payload = compat_fetch_v1_json(path, { date: params[:date] }.compact)
    return head :bad_gateway unless payload

    render json: payload
  end

  def date
    @date ||= params[:date].present? ? Time.zone.parse(params[:date]).to_date : Time.zone.now.to_date
  end

  def month_dates
    date.beginning_of_month.beginning_of_day..date.end_of_month.end_of_day
  end
end
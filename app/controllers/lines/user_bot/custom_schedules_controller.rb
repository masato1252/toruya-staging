# frozen_string_literal: true

class Lines::UserBot::CustomSchedulesController < Lines::UserBotDashboardController
    # show action for dynamic modal loading
  def show
    if compat_read_data_plane?
      owner_id = compat_custom_schedule_owner_id
      payload = compat_fetch_v1_json(
        "/lines/user_bot/owner/#{owner_id}/custom_schedules/#{params[:id]}",
        { current_user_id: resolve_compat_current_user_id(nil) }
      )&.dig("data")
      return head :not_found unless payload

      return render partial: 'reservations/off_date_modal_content', locals: {
        modal_id: "off-date-modal-#{payload["id"]}",
        custom_schedule_id: payload["id"],
        date: Date.parse(payload["start_time_date_part"]),
        start_time_date_part: payload["start_time_date_part"],
        start_time_time_part: payload["start_time_time_part"],
        end_time_date_part: payload["end_time_date_part"],
        end_time_time_part: payload["end_time_time_part"],
        calendarfield_prefix: "temp_leaving_schedule_#{payload["id"]}",
        reason: payload["reason"],
        open: payload["open"]
      }
    end

    custom_schedule = current_user.custom_schedules.find_by(id: params[:id])
    if custom_schedule.nil?
      head :not_found
      return
    end

    if custom_schedule_permission(custom_schedule)
      render partial: 'reservations/off_date_modal_content', locals: {
        modal_id: "off-date-modal-#{custom_schedule.id}",
        custom_schedule_id: custom_schedule.id,
        date: custom_schedule.start_time&.to_date || Date.current,
        start_time_date_part: custom_schedule.start_time_date,
        start_time_time_part: custom_schedule.start_time_time,
        end_time_date_part: custom_schedule.end_time_date,
        end_time_time_part: custom_schedule.end_time_time,
        calendarfield_prefix: "temp_leaving_schedule_#{custom_schedule.id}",
        reason: custom_schedule.reason,
        open: custom_schedule.open
      }
    else
      head :unprocessable_entity
    end
  end

  def create
    if compat_read_data_plane?
      result = compat_v1_post(
        "/lines/user_bot/owner/#{compat_custom_schedule_owner_id}/custom_schedules",
        compat_custom_schedule_attrs
      )
      return compat_custom_schedule_redirect(result)
    end

    # create from personal schedule
    CustomSchedules::PersonalCreate.run!(
      user: current_user,
      attrs: custom_schedules_params[:custom_schedules].first.to_h.merge(open: !params[:custom_schedules_closed])
    )

    enqueue_cache_refresh_for_user(current_user)
    redirect_back(fallback_location: SiteRouting.new(view_context).member_path)
  end

  # update from personal schedule, off schedule
  def update
    if compat_read_data_plane?
      result = compat_v1_put(
        "/lines/user_bot/owner/#{compat_custom_schedule_owner_id}/custom_schedules/#{params[:id]}",
        compat_custom_schedule_attrs
      )
      return compat_custom_schedule_redirect(result)
    end

    custom_schedule = current_user.custom_schedules.find(params[:id])

    if custom_schedule_permission(custom_schedule)
      CustomSchedules::Update.run(
        custom_schedule: custom_schedule,
        attrs: custom_schedules_params[:custom_schedules].first.to_h.merge(open: !params[:custom_schedules_closed])
      )

      enqueue_cache_refresh_for_custom_schedule(custom_schedule)
      redirect_back(fallback_location: SiteRouting.new(view_context).member_path)
    else
      head :unprocessable_entity
    end
  end

  # destroy from personal schedule, off schedule
  def destroy
    if compat_read_data_plane?
      result = compat_v1_delete(
        "/lines/user_bot/owner/#{compat_custom_schedule_owner_id}/custom_schedules/#{params[:id]}",
        { current_user_id: resolve_compat_current_user_id(nil) }
      )
      return compat_custom_schedule_redirect(result)
    end

    custom_schedule = current_user.custom_schedules.find(params[:id])

    if custom_schedule_permission(custom_schedule)
      enqueue_cache_refresh_for_custom_schedule(custom_schedule)
      CustomSchedules::Delete.run(custom_schedule: custom_schedule)

      redirect_back(fallback_location: SiteRouting.new(view_context).member_path)
    else
      head :unprocessable_entity
    end
  end

  private

  def custom_schedules_params
    params.permit(custom_schedules: [:id, :shop_id, :open, :start_time_date_part, :start_time_time_part, :end_time_date_part, :end_time_time_part, :reason, :_destroy])
  end

  def compat_custom_schedule_owner_id
    resolve_compat_owner_id(nil) || resolve_compat_current_user_id(nil)
  end

  def compat_custom_schedule_attrs
    custom_schedules_params[:custom_schedules].first.to_h.merge(
      open: !params[:custom_schedules_closed],
      current_user_id: resolve_compat_current_user_id(nil)
    )
  end

  def compat_custom_schedule_redirect(result)
    if result&.dig("status") == "successful"
      redirect_back(fallback_location: SiteRouting.new(view_context).member_path)
    else
      flash[:alert] = I18n.t("common.operation_failed", default: "更新に失敗しました")
      redirect_back(fallback_location: SiteRouting.new(view_context).member_path)
    end
  end

  def custom_schedule_permission(custom_schedule)
    custom_schedule.user_id == current_user.id || represent_staff_ids.include?(custom_schedule.staff_id)
  end

  def represent_staff_ids
    @represent_staff_ids ||= Current.business_owner.staff_ids
  end

  def enqueue_cache_refresh_for_user(user)
    BookingPage.where(shop_id: user.shops.select(:id)).find_each do |booking_page|
      BookingPageCacheJob.perform_later(booking_page)
    end
  end

  def enqueue_cache_refresh_for_custom_schedule(custom_schedule)
    if custom_schedule.shop_id.present?
      BookingPage.where(shop_id: custom_schedule.shop_id).find_each do |booking_page|
        BookingPageCacheJob.perform_later(booking_page)
      end
    elsif custom_schedule.staff_id.present? && custom_schedule.staff.present?
      BookingPage.where(shop_id: custom_schedule.staff.shops.select(:id)).find_each do |booking_page|
        BookingPageCacheJob.perform_later(booking_page)
      end
    elsif custom_schedule.user_id.present? && custom_schedule.user.present?
      enqueue_cache_refresh_for_user(custom_schedule.user)
    end
  end
end

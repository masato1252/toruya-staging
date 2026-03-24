# frozen_string_literal: true

class Lines::UserBot::CustomSchedulesController < Lines::UserBotDashboardController
    # show action for dynamic modal loading
  def show
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

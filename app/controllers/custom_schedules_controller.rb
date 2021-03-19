# frozen_string_literal: true

class CustomSchedulesController < DashboardController
  def create
    if params[:shop_ids].present?
      # create from shop dashboard, open working schedule
      params[:shop_ids].each do |shop_id|
        custom_schedules_params[:custom_schedules].each do |attrs|
          CustomSchedules::Change.run(owner: staff, attrs: attrs.to_h.merge(shop_id: shop_id))
        end
      end
    else
      # create from personal schedule
      CustomSchedules::PersonalCreate.run!(user: current_user, attrs: custom_schedules_params[:custom_schedules].first.to_h)
    end

    redirect_back(fallback_location: member_path)
  end

  # update from personal schedule, off schedule
  def update
    custom_schedule = CustomSchedule.find(params[:id])

    if custom_schedule_permission(custom_schedule)
      CustomSchedules::Update.run(custom_schedule: custom_schedule, attrs: custom_schedules_params[:custom_schedules].first.to_h)

      redirect_back(fallback_location: member_path)
    else
      head :unprocessable_entity
    end
  end

  # destroy from personal schedule, off schedule
  def destroy
    custom_schedule = CustomSchedule.find(params[:id])

    if custom_schedule_permission(custom_schedule)
      CustomSchedules::Delete.run(custom_schedule: custom_schedule)

      redirect_back(fallback_location: member_path)
    else
      head :unprocessable_entity
    end
  end

  private

  def custom_schedules_params
    params.permit(custom_schedules: [:id, :shop_id, :open, :start_time_date_part, :start_time_time_part, :end_time_time_part, :reason, :_destroy])
  end

  def custom_schedule_permission(custom_schedule)
    custom_schedule.user_id == current_user.id || represent_staff_ids.include?(custom_schedule.staff_id)
  end

  def represent_staff_ids
    @represent_staff_ids ||= working_shop_options(include_user_own: true).map(&:staff_id)
  end
end

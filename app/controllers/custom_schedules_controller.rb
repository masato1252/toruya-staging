class CustomSchedulesController < DashboardController
  def create
    if params[:shop_ids].present?
      params[:shop_ids].each do |shop_id|
        custom_schedules_params[:custom_schedules].each do |attrs|
          CustomSchedules::Create.run(staff: staff, attrs: attrs.to_h.merge(shop_id: shop_id))
        end
      end
    elsif params[:staff_id].present?
      custom_schedules_params[:custom_schedules].each do |attrs|
        CustomSchedules::Create.run(staff: staff, attrs: attrs.to_h)
      end
    else
      # Used in member dashboard, we won't set custom_schedules for particular staff, for all the staffs, users have permission.
      custom_schedules_params[:custom_schedules].each do |attrs|
        staffs_have_holiday_permission.each do |user_represent_staff|
          CustomSchedules::Create.run(staff: user_represent_staff, attrs: attrs.to_h)
        end
      end
    end

    redirect_back(fallback_location: member_path)
  end

  private

  def custom_schedules_params
    params.permit(custom_schedules: [:id, :shop_id, :open, :start_time_date_part, :start_time_time_part, :end_time_time_part, :reason, :_destroy, :reference_id])
  end

end

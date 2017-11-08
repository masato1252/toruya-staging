class CustomSchedulesController < DashboardController
  def create
    if params[:shop_ids].present?
      params[:shop_ids].each do |shop_id|
        custom_schedules_params[:custom_schedules].each do |attrs|
          CustomSchedules::Create.run(staff: staff, attrs: attrs.to_h.merge(shop_id: shop_id))
        end
      end
    else
      custom_schedules_params[:custom_schedules].each do |attrs|
        CustomSchedules::Create.run(staff: staff, attrs: attrs.to_h)
      end
    end

    redirect_back(fallback_location: root_path)
  end

  private

  def custom_schedules_params
    params.permit(custom_schedules: [:open, :start_time_date_part, :start_time_time_part, :end_time_time_part])
  end

end

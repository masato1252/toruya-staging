class CustomSchedulesController < DashboardController
  def create
    custom_schedules_params[:custom_schedules].each do |attrs|
      CustomSchedules::Create.run(staff: staff, attrs: attrs.to_h)
    end

    redirect_to :back
  end

  private

  def custom_schedules_params
    params.permit(custom_schedules: [:shop_id, :open, :start_time_date_part, :start_time_time_part, :end_time_time_part])
  end

end

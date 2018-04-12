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

    respond_to do |format|
      format.json { render json: {}, status: :ok }
      format.html { redirect_back(fallback_location: member_path) }
    end
  end

  private

  def custom_schedules_params
    params.permit(custom_schedules: [:id, :shop_id, :open, :start_time_date_part, :start_time_time_part, :end_time_time_part, :reason, :_destroy])
  end

end

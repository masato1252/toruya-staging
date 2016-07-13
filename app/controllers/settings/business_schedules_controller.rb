class Settings::BusinessSchedulesController < DashboardController
  layout "settings"

  def index
  end

  def edit
    @wdays_business_schedules = shop.business_schedules.for_shop.order(:days_of_week)
  end

  def update
    schedules_params[:business_schedules].each do |attrs|
      CreateSchedule.run(shop: shop, attrs: attrs.to_h)
    end

    redirect_to edit_settings_shop_business_schedules_path(shop)
  end

  private
  def schedules_params
    params.permit(business_schedules: [:id, :business_state, :days_of_week, :start_time, :end_time])
  end
end

class Settings::BusinessSchedulesController < DashboardController
  layout "settings"

  def index
  end

  def edit
    @wdays_business_schedules = shop.business_schedules.for_shop.order(:days_of_week)
    @custom_schedules = shop.custom_schedules.for_shop.where("start_time > ?", Time.now.yesterday).order(:start_time)
  end

  def update
    business_schedules_params[:business_schedules].each do |attrs|
      CreateBusinessSchedule.run(shop: shop, attrs: attrs.to_h)
    end

    custom_schedules_params[:custom_schedules].each do |attrs|
      CreateCustomSchedule.run(shop: shop, attrs: attrs.to_h)
    end

    redirect_to edit_settings_shop_business_schedules_path(shop)
  end

  private

  def business_schedules_params
    params.permit(business_schedules: [:id, :business_state, :days_of_week, :start_time, :end_time])
  end

  def custom_schedules_params
    params.permit(custom_schedules: [:id, :start_time_date_part, :start_time_time_part, :end_time, :reason])
  end
end

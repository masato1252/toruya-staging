class Settings::BusinessSchedulesController < SettingsController
  def index
  end

  def edit
    @wdays_business_schedules = shop.business_schedules.for_shop.order(:day_of_week)
    @custom_schedules = shop.custom_schedules.for_shop.order(:start_time)
  end

  def update
    business_schedules_params[:business_schedules].each do |attrs|
      CreateBusinessSchedule.run(shop: shop, attrs: attrs.to_h)
    end

    custom_schedules_params[:custom_schedules].each do |attrs|
      CreateCustomSchedule.run(shop: shop, attrs: attrs.to_h)
    end if custom_schedules_params[:custom_schedules]

    update_shop = UpdateShop.run(shop: shop, holiday_working: shop_params[:shop].try(:[], :holiday_working))

    flash[:alert] = update_shop.errors.full_messages.join(", ")

    redirect_to settings_business_schedules_path
  end

  private

  def business_schedules_params
    params.permit(business_schedules: [:id, :business_state, :day_of_week, :start_time, :end_time])
  end

  def custom_schedules_params
    params.permit(custom_schedules: [:id, :start_time_date_part, :start_time_time_part, :end_time, :reason, :_destroy])
  end

  def shop_params
    params.permit(shop: :holiday_working)
  end
end

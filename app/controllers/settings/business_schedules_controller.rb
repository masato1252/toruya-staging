class Settings::BusinessSchedulesController < SettingsController
  def index
  end

  def edit
    @wdays_business_schedules = shop.business_schedules.for_shop.order(:day_of_week)
    @custom_schedules = shop.custom_schedules.for_shop.future.order(:start_time)
  end

  def update
    business_schedules_params[:business_schedules].each do |attrs|
      CreateBusinessSchedule.run(shop: shop, attrs: attrs.to_h)
    end

    custom_schedules_params[:custom_schedules].each do |attrs|
      CreateCustomSchedule.run(shop: shop, attrs: attrs.to_h)
    end if custom_schedules_params[:custom_schedules]

    update_shop = UpdateShop.run(shop: shop, holiday_working: shop_params[:shop].try(:[], :holiday_working))

    # Recalculate repeating dates
    ShopMenuRepeatingDate.
      includes(menu: [:menu_reservation_setting_rule, :reservation_setting]).where(shop: shop).
      future.each do |menu_repeating_date|
        menu = menu_repeating_date.menu
        shop_repeating_dates =  Menus::RetrieveRepeatingDates.run!(reservation_setting_id: menu.reservation_setting.id,
                                                                   shop_ids: [shop.id],
                                                                   repeats: menu.menu_reservation_setting_rule.repeats,
                                                                   start_date: menu.menu_reservation_setting_rule.start_date)

        menu_repeating_date.dates = shop_repeating_dates.first[:dates]
        menu_repeating_date.end_date = shop_repeating_dates.first[:dates].last
        menu_repeating_date.save
      end

    flash[:alert] = update_shop.errors.full_messages.join(", ")

    redirect_to settings_business_schedules_path
  end

  private

  def business_schedules_params
    params.permit(business_schedules: [:id, :business_state, :day_of_week, :start_time, :end_time])
  end

  def custom_schedules_params
    params.permit(custom_schedules: [:id, :start_time_date_part, :start_time_time_part, :end_time_time_part, :reason, :_destroy])
  end

  def shop_params
    params.permit(shop: :holiday_working)
  end
end

# frozen_string_literal: true

class Lines::UserBot::Settings::BusinessSchedulesController < Lines::UserBotDashboardController
  def shops
    @shops = Current.business_owner.shops
  end

  def index
    @wdays_business_schedules_mapping = shop.business_schedules.opened.for_shop.group_by(&:day_of_week)
    @holiday_working_schedules = shop.business_schedules.opened.for_shop.holiday_working
  end

  def edit
    @business_schedules = shop.business_schedules.opened.for_shop.where(day_of_week: params[:wday])
  end

  def update
    permit_hash = params.permit!.to_h
    outcome = BusinessSchedules::Update.run(
      shop: shop,
      business_state: params[:business_state],
      day_of_week: params[:wday],
      business_schedules: permit_hash[:business_schedules]
    )

    render json: json_response(outcome, { redirect_to: index_lines_user_bot_settings_business_schedules_path(shop_id: params[:shop_id], business_owner_id: business_owner_id) })
  end

  private

  def shop
    @shop ||= Current.business_owner.shops.find(params[:shop_id]) if params[:shop_id]
  end
end

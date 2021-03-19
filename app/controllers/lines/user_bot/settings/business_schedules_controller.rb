# frozen_string_literal: true

class Lines::UserBot::Settings::BusinessSchedulesController < Lines::UserBotDashboardController
  def shops
    @shops = current_user.shops
  end

  def index
    @wdays_business_schedules = shop.business_schedules.for_shop.order(:day_of_week)
  end

  def edit
    @business_schedule = shop.business_schedules.find(params[:id])
  end

  def update
    outcome = BusinessSchedules::Update.run(shop: shop, attrs: params.permit!.to_h)

    render json: json_response(outcome, { redirect_to: index_lines_user_bot_settings_business_schedules_path(shop_id: params[:shop_id]) })
  end

  private

  def shop
    @shop ||= current_user.shops.find(params[:shop_id])
  end
end

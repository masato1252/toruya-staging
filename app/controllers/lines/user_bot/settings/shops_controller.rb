# frozen_string_literal: true

class Lines::UserBot::Settings::ShopsController < Lines::UserBotDashboardController
  def edit
    @shop = current_user.shops.find(params[:shop_id])
  end

  def update
    shop = current_user.shops.find(shop_params[:id])
    outcome = Shops::Update.run(shop: shop, params: shop_params.to_h)

    case params[:attribute]
    when "holiday_working"
      render json: json_response(outcome, { redirect_to: index_lines_user_bot_settings_business_schedules_path(shop_id: shop_params[:id]) })
    else
    end
  end

  private

  def shop_params
    params.require(:shop).permit(:id, :holiday_working)
  end
end

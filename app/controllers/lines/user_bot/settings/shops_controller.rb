# frozen_string_literal: true

class Lines::UserBot::Settings::ShopsController < Lines::UserBotDashboardController
  def index
    @shops = Current.business_owner.shops
  end

  def show
    @shop = Current.business_owner.shops.find(params[:id])
  end

  def edit
    @shop = Current.business_owner.shops.find(params[:id])

    if params[:attribute] == "holiday_working"
      @business_schedules = shop.business_schedules.opened.for_shop.holiday_working
      @title = I18n.t("user_bot.dashboards.settings.business_schedules.holiday_label")
      @previous_path = index_lines_user_bot_settings_business_schedules_path(business_owner_id, shop_id: params[:id])
      @header = I18n.t("user_bot.dashboards.settings.business_schedules.holiday_label")
    else
      @title = I18n.t("user_bot.dashboards.settings.shop.shop_info_label")
      @previous_path = lines_user_bot_settings_shop_path(business_owner_id, params[:id])
      @header = I18n.t("user_bot.dashboards.settings.shop.#{params[:attribute]}_label")
    end
  end

  def update
    shop = Current.business_owner.shops.find(params[:id])
    outcome = Shops::Update.run(shop: shop, params: shop_params.to_h)

    case params[:attribute]
    when "holiday_working"
      return_json_response(outcome, { redirect_to: index_lines_user_bot_settings_business_schedules_path(business_owner_id, shop_id: params[:id]) })
    else
      return_json_response(outcome, { redirect_to: lines_user_bot_settings_shop_path(business_owner_id, shop_id: params[:id]) })
    end
  end

  def custom_messages
  end

  private

  def shop_params
    params.permit(:holiday_working, :name, :short_name, :phone_number, :website, :email, :logo, business_schedules: [:start_time, :end_time], address_details: [:zip_code, :region, :city, :street1, :street2])
  end
end

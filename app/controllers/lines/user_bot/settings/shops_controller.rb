# frozen_string_literal: true

class Lines::UserBot::Settings::ShopsController < Lines::UserBotDashboardController
  def index
    @shops = current_user.shops
  end

  def show
    @shop = current_user.shops.find(params[:id])
  end

  def edit
    @shop = current_user.shops.find(params[:id])
    @title =
      case params[:attribute]
      when "holiday_working"
        I18n.t("user_bot.dashboards.settings.business_schedules.holiday_label")
      else
        I18n.t("user_bot.dashboards.settings.shop.shop_info_label")
      end

    @previous_path =
      case params[:attribute]
      when "holiday_working"
        index_lines_user_bot_settings_business_schedules_path(shop_id: params[:id])
      else
        lines_user_bot_settings_shop_path(params[:id])
      end

    @header =
      case params[:attribute]
      when "holiday_working"
        I18n.t("user_bot.dashboards.settings.business_schedules.holiday_label")
      when "name", "address", "phone_number", "email", "website", "logo"
        I18n.t("user_bot.dashboards.settings.shop.#{params[:attribute]}_label")
      end
  end

  def update
    shop = current_user.shops.find(params[:id])
    outcome = Shops::Update.run(shop: shop, params: shop_params.to_h)

    case params[:attribute]
    when "holiday_working"
      render json: json_response(outcome, { redirect_to: index_lines_user_bot_settings_business_schedules_path(shop_id: params[:id]) })
    else
      render json: json_response(outcome, { redirect_to: lines_user_bot_settings_shop_path(shop_id: params[:id]) })
    end
  end

  private

  def shop_params
    params.permit(:holiday_working, :name, :short_name, :phone_number, :website, :email, :logo, address_details: [:zip_code, :region, :city, :street1, :street2])
  end
end

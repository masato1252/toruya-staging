# frozen_string_literal: true

class Lines::UserBot::Settings::MenusController < Lines::UserBotDashboardController
  def index
    @menus = Current.business_owner.menus.order("id")
  end

  def show
    @menu = Current.business_owner.menus.find(params[:id])

    @menu_shops = @menu.shop_menus.includes(:shop)
  end

  def edit
    @menu = Current.business_owner.menus.find(params[:id])

    case params[:attribute]
    when "menu_shops"
      shop_menus = @menu.shop_menus.includes(:shop).to_a
      @menu_shops_options = Current.business_owner.shops.map do |shop|
        if shop_menu = shop_menus.find { |shop_menu| shop_menu.shop_id == shop.id }
          Option.new(name: shop.display_name, shop_id: shop.id, max_seat_number: shop_menu.max_seat_number, checked: true)
        else
          Option.new(name: shop.display_name, shop_id: shop.id, max_seat_number: "", checked: false)
        end
      end
    end
  end

  def update
    menu = Current.business_owner.menus.find(params[:id])
    outcome = ::Menus::UpdateAttribute.run(menu: menu, attrs: params.permit!.to_h, update_attribute: params[:attribute])

    return_json_response(outcome, { redirect_to: lines_user_bot_settings_menu_path(params[:id], anchor: params[:attribute]) })
  end

  def destroy
    menu = Current.business_owner.menus.find(params[:id])
    outcome = ::Menus::Delete.run(menu: menu)

    if outcome.valid?
      redirect_to lines_user_bot_settings_menus_path(Current.business_owner), notice: I18n.t("common.delete_successfully_message")
    else
      redirect_to lines_user_bot_settings_menu_path(menu), flash: { alert: I18n.t("active_interaction.errors.models.menus/delete.attributes.menu.be_used_by_booking_page") }
    end
  end
end

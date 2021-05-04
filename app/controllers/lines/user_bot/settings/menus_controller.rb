# frozen_string_literal: true

class Lines::UserBot::Settings::MenusController < Lines::UserBotDashboardController
  def index
    @menus = current_user.menus.order("id")
  end

  def show
    @menu = current_user.menus.find(params[:id])

    @menu_shops = @menu.shop_menus.includes(:shop)
  end

  def edit
    @menu = current_user.menus.find(params[:id])

    case params[:attribute]
    when "menu_shops"
      shop_menus = @menu.shop_menus.includes(:shop).to_a
      @menu_shops_options = current_user.shops.map do |shop|
        if shop_menu = shop_menus.find { |shop_menu| shop_menu.shop_id == shop.id }
          Option.new(name: shop.display_name, shop_id: shop.id, max_seat_number: shop_menu.max_seat_number, checked: true)
        else
          Option.new(name: shop.display_name, shop_id: shop.id, max_seat_number: "", checked: false)
        end
      end
    end
  end

  def update
    menu = current_user.menus.find(params[:id])
    outcome = ::Menus::UpdateAttribute.run(menu: menu, attrs: params.permit!.to_h, update_attribute: params[:attribute])

    return_json_response(outcome, { redirect_to: lines_user_bot_settings_menu_path(params[:id], anchor: params[:attribute]) })
  end
end

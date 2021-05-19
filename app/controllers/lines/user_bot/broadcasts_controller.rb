# frozen_string_literal: true

class Lines::UserBot::BroadcastsController < Lines::UserBotDashboardController
  def index
    @broadcasts = current_user.broadcasts.ordered
  end

  def show
    @broadcast = current_user.broadcasts.find(params[:id])
  end

  def new
    menus_options =
      current_user.menus.map do |menu|
        ::Options::MenuOption.new(id: menu.id, name: menu.display_name)
      end
    @menus = ::Menus::CategoryGroup.run!(menu_options: menus_options)
  end

  def edit
    @broadcast = current_user.broadcasts.find(params[:id])
    shop_menus_options =
      ShopMenu.includes(:menu).where(shop: current_user.shops).map do |shop_menu|
        ::Options::MenuOption.new(
          id: shop_menu.menu_id,
          name: shop_menu.menu.display_name,
          min_staffs_number: shop_menu.menu.min_staffs_number,
          available_seat: shop_menu.max_seat_number,
          minutes: shop_menu.menu.minutes,
          interval: shop_menu.menu.interval
        )
      end
    @menus = ::Menus::CategoryGroup.run!(menu_options: shop_menus_options)
  end

  def create
    outcome = Broadcasts::Create.run(user: current_user, params: params[:broadcast].permit!.to_h)

    return_json_response(outcome, { redirect_to: lines_user_bot_broadcasts_path })
  end

  def update
    outcome = Broadcasts::Update.run(broadcast: current_user.broadcasts.find(params[:id]), params: params[:broadcast].permit!.to_h)

    return_json_response(outcome, { redirect_to: lines_user_bot_broadcasts_path })
  end

  def draft
    broadcast = current_user.broadcasts.find(params[:id])
    Broadcasts::Draft.run(broadcast: broadcast)

    redirect_to lines_user_bot_broadcast_path(broadcast)
  end
end

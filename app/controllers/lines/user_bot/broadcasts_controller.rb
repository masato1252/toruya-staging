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
        ::Options::MenuOption.new(id: menu.id, name: menu.display_name, online: menu.online)
      end
    @menus = ::Menus::CategoryGroup.run!(menu_options: menus_options)
  end

  def edit
    @broadcast = current_user.broadcasts.find(params[:id])
    menus_options =
      current_user.menus.map do |menu|
        ::Options::MenuOption.new(id: menu.id, name: menu.display_name, online: menu.online)
      end
    @menus = ::Menus::CategoryGroup.run!(menu_options: menus_options)
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

  def customers_count
    outcome =
      case params[:query_type]
      when "online_service_for_active_customers"
        Broadcasts::QueryActiveServiceCustomers.run(user: current_user, query: params[:query].permit!.to_h)
      else
        Broadcasts::QueryCustomers.run(user: current_user, query: params[:query].permit!.to_h)
      end

    return_json_response(outcome, { customers_count: outcome.result.count })
  end
end

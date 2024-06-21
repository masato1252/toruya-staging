# frozen_string_literal: true

class Lines::UserBot::BroadcastsController < Lines::UserBotDashboardController
  def index
    @broadcasts = Current.business_owner.broadcasts.ordered.normal.where("created_at > ?", 6.months.ago)
  end

  def show
    @broadcast = Current.business_owner.broadcasts.find(params[:id])
  end

  def new
    menus_options =
      Current.business_owner.menus.map do |menu|
        ::Options::MenuOption.new(id: menu.id, name: menu.display_name, online: menu.online)
      end
    @menus = ::Menus::CategoryGroup.run!(menu_options: menus_options)
    @online_services = Current.business_owner.online_services.order("updated_at DESC").map { |service|
      {
        label: service.internal_name.presence || service.name,
        value: OnlineServiceOptionSerializer.new(service).attributes_hash
      }
    }
  end

  def edit
    @broadcast = Current.business_owner.broadcasts.find(params[:id])
    menus_options =
      Current.business_owner.menus.map do |menu|
        ::Options::MenuOption.new(id: menu.id, name: menu.display_name, online: menu.online)
      end
    @menus = ::Menus::CategoryGroup.run!(menu_options: menus_options)
    @attribute = params[:attribute]
    @online_services = Current.business_owner.online_services.order("updated_at DESC").map { |service|
      {
        label: service.internal_name.presence || service.name,
        value: OnlineServiceOptionSerializer.new(service).attributes_hash
      }
    }
  end

  def create
    outcome = Broadcasts::Create.run(user: Current.business_owner, params: params.permit!.to_h)

    return_json_response(outcome, { redirect_to: lines_user_bot_broadcasts_path(business_owner_id: business_owner_id) })
  end

  def update
    outcome = Broadcasts::Update.run(broadcast: Current.business_owner.broadcasts.find(params[:id]), params: params.permit!.to_h, update_attribute: params[:attribute])

    if outcome.valid?
      return_json_response(outcome, { redirect_to: lines_user_bot_broadcast_path(outcome.result, business_owner_id: business_owner_id) })
    else
      return_json_response(outcome)
    end
  end

  def draft
    broadcast = Current.business_owner.broadcasts.find(params[:id])
    Broadcasts::Draft.run(broadcast: broadcast)

    redirect_to lines_user_bot_broadcast_path(broadcast, business_owner_id: business_owner_id)
  end

  def activate
    broadcast = Current.business_owner.broadcasts.find(params[:id])
    Broadcasts::Activate.run(broadcast: broadcast)

    redirect_to lines_user_bot_broadcast_path(broadcast, business_owner_id: business_owner_id)
  end

  def clone
    broadcast = Current.business_owner.broadcasts.find(params[:id])
    new_broadcast = Broadcasts::Clone.run!(broadcast: broadcast)

    redirect_to lines_user_bot_broadcasts_path(business_owner_id: business_owner_id), notice: I18n.t("user_bot.dashboards.broadcasts.clone_successfully")
  end

  def customers_count
    outcome =
      case params[:query_type]
      when "online_service_for_active_customers"
        Broadcasts::QueryActiveServiceCustomers.run(user: Current.business_owner, query: params[:query].permit!.to_h)
      else
        Broadcasts::QueryCustomers.run(user: Current.business_owner, query: params[:query].permit!.to_h)
      end

    return_json_response(outcome, { customers_count: outcome.result.count })
  end
end

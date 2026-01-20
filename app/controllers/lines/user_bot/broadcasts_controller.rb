# frozen_string_literal: true

class Lines::UserBot::BroadcastsController < Lines::UserBotDashboardController
  def index
    @broadcasts = Current.business_owner.broadcasts.ordered.normal
  end

  def show
    @broadcast = Current.business_owner.broadcasts.find(params[:id])
    @customers = Broadcasts::FilterCustomers.run!(broadcast: @broadcast)
    @broadcast.update(customers_permission_warning: @customers.any? { |customer| !customer.reminder_permission })
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
    @broadcast =
      if params[:online_service_id]
        Broadcast.new(
          query_type: "online_service_for_active_customers",
          query: {
            "filters" => [{
              "field" => "online_service_ids",
              "value" => params[:online_service_id],
              "condition" => "contains"
            }],
            "operator" => "or"
          },
          content: "",
        )
      else
        {}
      end
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
    flash[:notice] = I18n.t("common.create_successfully_message")

    return_json_response(outcome, { redirect_to: lines_user_bot_broadcast_path(outcome.result, business_owner_id: business_owner_id) })
  end

  def update
    outcome = Broadcasts::Update.run(broadcast: Current.business_owner.broadcasts.find(params[:id]), params: params.permit!.to_h, update_attribute: params[:attribute])

    if outcome.valid?
      flash[:notice] = I18n.t("common.update_successfully_message")

      return_json_response(outcome, { redirect_to: lines_user_bot_broadcast_path(outcome.result, business_owner_id: business_owner_id) })
    else
      return_json_response(outcome)
    end
  end

  def draft
    broadcast = Current.business_owner.broadcasts.find(params[:id])
    Broadcasts::Draft.run(broadcast: broadcast)
    flash[:notice] = I18n.t("common.update_successfully_message")

    redirect_to lines_user_bot_broadcast_path(broadcast, business_owner_id: business_owner_id)
  end

  def activate
    broadcast = Current.business_owner.broadcasts.find(params[:id])
    Broadcasts::Activate.run(broadcast: broadcast)
    flash[:notice] = I18n.t("common.update_successfully_message")

    redirect_to lines_user_bot_broadcast_path(broadcast, business_owner_id: business_owner_id)
  end

  def clone
    broadcast = Current.business_owner.broadcasts.find(params[:id])
    Broadcasts::Clone.run!(broadcast: broadcast)

    redirect_to lines_user_bot_broadcasts_path(business_owner_id: business_owner_id), notice: I18n.t("user_bot.dashboards.broadcasts.clone_successfully")
  end

  def customers_count
    customers =
      case params[:query_type]
      when "active_customers"
        Current.business_owner.customers.active_in(3.months.ago)
      when "online_service_for_active_customers"
        outcome = Broadcasts::QueryActiveServiceCustomers.run(user: Current.business_owner, query: params[:query].permit!.to_h)
        outcome.result
      else
        outcome = Broadcasts::QueryCustomers.run(user: Current.business_owner, query: params[:query].permit!.to_h)
        outcome.result
      end

    # Apply blacklist filter
    filtered_customers = customers.select { |customer| !customer.in_blacklist? }
    
    # Apply reminder_permission filter for marketing broadcasts
    # reservation_customers and manual_assignment don't require reminder_permission
    unless ["reservation_customers", "manual_assignment"].include?(params[:query_type])
      filtered_customers = filtered_customers.select { |customer| customer.reminder_permission }
    end

    render json: { customers_count: filtered_customers.count }
  end
end

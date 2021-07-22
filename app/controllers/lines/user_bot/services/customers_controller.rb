# frozen_string_literal: true

class Lines::UserBot::Services::CustomersController < Lines::UserBotDashboardController
  def index
    @online_service = current_user.online_services.find(params[:service_id])
    @relations = @online_service.online_service_customer_relations.uncanceled.includes(:customer)
    @available_count = @online_service.online_service_customer_relations.available.size
  end

  def show
    @online_service = current_user.online_services.find(params[:service_id])
    @relation = @online_service.online_service_customer_relations.find(params[:id])
    @customer = @relation.customer
  end

  def approve
    online_service = current_user.online_services.find(params[:service_id])
    relation = online_service.online_service_customer_relations.find(params[:id])

    ::Sales::OnlineServices::Approve.run!(relation: relation, online_service: online_service, customer: relation.customer)

    redirect_to lines_user_bot_service_customer_path(service_id: online_service.id, id: relation.id)
  end

  def cancel
    online_service = current_user.online_services.find(params[:service_id])
    relation = online_service.online_service_customer_relations.find(params[:id])

    ::Sales::OnlineServices::Cancel.run!(relation: relation)

    redirect_to lines_user_bot_service_customers_path(service_id: online_service.id)
  end
end

# frozen_string_literal: true

class Lines::UserBot::Services::CustomersController < Lines::UserBotDashboardController
  def index
    @online_service = current_user.online_services.find(params[:service_id])
    @relations = @online_service.all_online_service_customer_relations.includes(:customer, :last_customer_payment).order("online_service_customer_relations.created_at DESC")
    @available_count = @online_service.online_service_customer_relations.available.size
  end

  def show
    @online_service = current_user.online_services.find(params[:service_id])
    @relation = @online_service.online_service_customer_relations.find(params[:id])
    @customer = @relation.customer
    @is_owner = true
  end

  def approve
    online_service = current_user.online_services.find(params[:service_id])
    relation = online_service.online_service_customer_relations.find(params[:id])

    ::Sales::OnlineServices::Approve.run!(relation: relation)

    redirect_to lines_user_bot_service_customer_path(service_id: online_service.id, id: relation.id)
  end

  def cancel
    online_service = current_user.online_services.find(params[:service_id])
    relation = online_service.online_service_customer_relations.find(params[:id])

    ::Sales::OnlineServices::Cancel.run!(relation: relation)

    redirect_to lines_user_bot_service_customer_path(service_id: online_service.id, id: relation.id)
  end
end

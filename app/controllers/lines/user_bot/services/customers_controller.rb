# frozen_string_literal: true

class Lines::UserBot::Services::CustomersController < Lines::UserBotDashboardController
  def index
    @online_service = current_user.online_services.find(params[:service_id])
    @relations = @online_service.online_service_customer_relations.includes(:customer)
    @available_count = @online_service.online_service_customer_relations.available.size
  end

  def show
    @online_service = current_user.online_services.find(params[:service_id])
    @relation = @online_service.online_service_customer_relations.find(params[:id])
    @customer = @relation.customer
  end
end

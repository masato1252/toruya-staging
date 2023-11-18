# frozen_string_literal: true

class Lines::UserBot::Services::CustomersController < Lines::UserBotDashboardController
  def index
    @online_service = Current.business_owner.online_services.find(params[:service_id])
    @relations = @online_service.all_online_service_customer_relations.includes(:customer, :last_customer_payment).order("online_service_customer_relations.created_at DESC")
    @available_count = @online_service.online_service_customer_relations.available.size
  end

  def show
    @online_service = Current.business_owner.online_services.find(params[:service_id])
    @relation = @online_service.all_online_service_customer_relations.find(params[:id])
    @customer = @relation.customer
    @is_owner = true
  end

  def approve
    online_service = Current.business_owner.online_services.find(params[:service_id])
    relation = online_service.online_service_customer_relations.find(params[:id])

    ::Sales::OnlineServices::Approve.run!(relation: relation)

    redirect_to lines_user_bot_service_customer_path(business_owner_id: business_owner_id, service_id: online_service.id, id: relation.id)
  end

  def cancel
    online_service = Current.business_owner.online_services.find(params[:service_id])
    relation = online_service.online_service_customer_relations.find(params[:id])

    ::Sales::OnlineServices::Cancel.run!(relation: relation)

    redirect_to lines_user_bot_service_customer_path(business_owner_id: business_owner_id, service_id: online_service.id, id: relation.id)
  end

  def change_expire_at
    online_service = Current.business_owner.online_services.find(params[:service_id])
    relation = online_service.online_service_customer_relations.find(params[:id])

    CustomerPayments::ChangeServiceExpireAt.run!(
      online_service_customer_relation: relation,
      expire_at: params[:expire_at],
      memo: params[:memo]
    )

    redirect_to lines_user_bot_service_customer_path(service_id: online_service.id, id: relation.id)
  end
end

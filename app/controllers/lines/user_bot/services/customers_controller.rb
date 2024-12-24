# frozen_string_literal: true

class Lines::UserBot::Services::CustomersController < Lines::UserBotDashboardController
  def index
    @online_service = Current.business_owner.online_services.find(params[:service_id])
    @relations = @online_service.all_online_service_customer_relations.includes(:customer, :last_customer_payment).order("online_service_customer_relations.created_at DESC")
    @available_count = @online_service.online_service_customer_relations.available.size
    @available_customers = current_user.customers.where.not(id: @relations.pluck(:customer_id))
  end

  def show
    @online_service = Current.business_owner.online_services.find(params[:service_id])
    @relation = @online_service.all_online_service_customer_relations.find(params[:id])
    @customer = @relation.customer
    @is_owner = true
  end

  def assign
    @online_service = Current.business_owner.online_services.find(params[:service_id])
    @customer = current_user.customers.find(params[:customer_id])

    outcome = Sales::OnlineServices::Assign.run(
      online_service: @online_service,
      customer: @customer,
      payment_type: SalePage::PAYMENTS[:assignment]
    )

    if outcome.invalid?
      Rollbar.error("Sales::OnlineServices::Assign failed", {
        errors: outcome.errors.details,
        params: params
      })
      flash[:alert] = I18n.t("common.update_failed_message")
    else
      flash[:notice] = I18n.t("common.update_successfully_message")
    end

    redirect_to lines_user_bot_service_customers_path(business_owner_id: business_owner_id, service_id: @online_service.id)
  end

  def approve
    online_service = Current.business_owner.online_services.find(params[:service_id])
    relation = online_service.online_service_customer_relations.find(params[:id])

    ::Sales::OnlineServices::Approve.run!(relation: relation)
    CustomerPayments::ApproveManually.run(online_service_customer_relation: relation)
    
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

    redirect_to lines_user_bot_service_customer_path(business_owner_id: business_owner_id, service_id: online_service.id, id: relation.id)
  end
end

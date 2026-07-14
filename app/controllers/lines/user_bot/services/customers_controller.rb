# frozen_string_literal: true

class Lines::UserBot::Services::CustomersController < Lines::UserBotDashboardController
  include CrossAccountRedirect
  redirect_to_correct_owner_for :online_services, param_key: :service_id

  def index
    if compat_read_enabled?
      render :index_compat
      return
    end

    @online_service = Current.business_owner.online_services.find(params[:service_id])
    relations = @online_service.all_online_service_customer_relations.includes(:customer, :last_customer_payment, :online_service).to_a
    state_order = { "pending" => 1, "accessible" => 2, "available" => 3, "inactive" => 4 }
    @relations = relations.sort_by { |relation| [state_order[relation.state], -relation.updated_at.to_i] }
    @available_count = @online_service.online_service_customer_relations.available.size
    @assignable_customers = current_user.customers.where.not(id: @online_service.online_service_customer_relations.available.map(&:customer_id))
  end

  def show
    if compat_read_data_plane?
      render :show_compat
      return
    end

    @online_service = Current.business_owner.online_services.find(params[:service_id])
    @relation = @online_service.all_online_service_customer_relations.find(params[:id])
    @customer = @relation.customer
    @is_owner = true
  end

  def assign
    return compat_service_customer_mutation("assign", customer_id: params[:customer_id]) if compat_read_data_plane?

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
    return compat_service_customer_mutation("approve") if compat_read_data_plane?

    online_service = Current.business_owner.online_services.find(params[:service_id])
    relation = online_service.online_service_customer_relations.find(params[:id])

    ::Sales::OnlineServices::Approve.run!(relation: relation, manual: true)
    if online_service.bundler?
      ::Sales::OnlineServices::ApproveBundlerService.run!(relation: relation)
    end
    CustomerPayments::ApproveManually.run(online_service_customer_relation: relation)

    redirect_to lines_user_bot_service_customer_path(business_owner_id: business_owner_id, service_id: online_service.id, id: relation.id)
  end

  def cancel
    return compat_service_customer_mutation("cancel") if compat_read_data_plane?

    online_service = Current.business_owner.online_services.find(params[:service_id])
    relation = online_service.online_service_customer_relations.find(params[:id])

    ::Sales::OnlineServices::Cancel.run!(relation: relation)

    redirect_to lines_user_bot_service_customer_path(business_owner_id: business_owner_id, service_id: online_service.id, id: relation.id)
  end

  def change_expire_at
    if compat_read_data_plane?
      return compat_service_customer_mutation(
        "change_expire_at",
        body: { expire_at: params[:expire_at], memo: params[:memo] }
      )
    end

    online_service = Current.business_owner.online_services.find(params[:service_id])
    relation = online_service.online_service_customer_relations.find(params[:id])

    CustomerPayments::ChangeServiceExpireAt.run!(
      online_service_customer_relation: relation,
      expire_at: params[:expire_at],
      memo: params[:memo]
    )

    redirect_to lines_user_bot_service_customer_path(business_owner_id: business_owner_id, service_id: online_service.id, id: relation.id)
  end

  def change_stripe_subscription_id
    if compat_read_data_plane?
      return compat_service_customer_mutation(
        "change_stripe_subscription_id",
        body: { stripe_subscription_id: params[:stripe_subscription_id] }
      )
    end

    online_service = Current.business_owner.online_services.find(params[:service_id])
    relation = online_service.online_service_customer_relations.find(params[:id])
    CustomerPayments::ChangeStripeSubscriptionId.run!(
      online_service_customer_relation: relation,
      stripe_subscription_id: params[:stripe_subscription_id]
    )
    redirect_to lines_user_bot_service_customer_path(business_owner_id: business_owner_id, service_id: online_service.id, id: relation.id)
  end

  private

  def compat_service_customer_mutation(action, customer_id: nil, body: nil)
    owner_id = resolve_compat_owner_id(nil) || resolve_compat_current_user_id(nil)
    path = "/lines/user_bot/owner/#{owner_id}/services/#{params[:service_id]}/customers"
    path = "#{path}/assign" if action == "assign"
    path = "#{path}/#{params[:id]}/#{action}" unless action == "assign"
    body ||= customer_id ? { customer_id: customer_id } : {}
    result =
      if action == "cancel"
        compat_v1_delete(path, body)
      elsif %w[change_expire_at change_stripe_subscription_id].include?(action)
        compat_v1_put(path, body)
      else
        compat_v1_post(path, body)
      end

    if result&.dig("status") == "successful"
      redirect_to(result.dig("data", "redirect_to").presence || lines_user_bot_service_customers_path(business_owner_id: owner_id, service_id: params[:service_id]))
    else
      flash[:alert] = I18n.t("common.update_failed_message")
      redirect_to lines_user_bot_service_customers_path(business_owner_id: owner_id, service_id: params[:service_id])
    end
  end
end

# frozen_string_literal: true

class Lines::UserBot::Customers::PaymentsController < Lines::UserBotDashboardController
  include CrossAccountRedirect
  redirect_to_correct_owner_for :customers, param_key: :customer_id

  before_action :set_customer, only: [:index]

  def index
    if compat_read_enabled?
      owner_id = resolve_compat_owner_id(nil) || resolve_compat_current_user_id(nil)
      payload = owner_id && compat_fetch_v1_json(
        "/lines/user_bot/owner/#{owner_id}/customer/payments",
        { customer_id: params[:customer_id] }
      )

      if payload
        render json: payload
      else
        render json: { status: "failed", error_message: "決済情報の取得に失敗しました" }, status: :bad_gateway
      end
      return
    end

    customer_payments = CustomerPayments::All.run!(customer: @customer)

    payments = CustomerPaymentSerializer.new(customer_payments).serializable_hash[:data].map do |h|
      h[:attributes]
    end

    render json: {
      payments: payments
    }
  end

  def refund_modal
    @payment = CustomerPayment.find(params[:id])
    render layout: false
  end

  def refund
    if compat_read_data_plane?
      owner_id = resolve_compat_owner_id(nil) || resolve_compat_current_user_id(nil)
      result = compat_v1_post(
        "/lines/user_bot/owner/#{owner_id}/customer/payments/#{params[:id]}/refund?customer_id=#{params[:customer_id]}",
        { amount: params[:amount] }
      )
      redirect_path = lines_user_bot_customers_path(
        business_owner_id: owner_id,
        customer_id: params[:customer_id],
        user_id: owner_id,
        target_view: Customer::DASHBOARD_TARGET_VIEWS[:payments]
      )

      if result&.dig("status") == "successful"
        redirect_to redirect_path
      else
        redirect_to redirect_path, alert: I18n.t("common.operation_failed", default: "返金に失敗しました")
      end
      return
    end

    customer_payment = CustomerPayment.find(params[:id])
    outcome = CustomerPayments::Refund.run(
      customer_payment: customer_payment,
      amount: Money.new(params[:amount], customer_payment.amount.currency.iso_code)
    )

    if outcome.invalid?
      Rollbar.error(
        "Unexpected CustomerPayments::Refund",
        errors: outcome.errors.details
      )
      redirect_to lines_user_bot_customers_path(business_owner_id: Current.business_owner.id, customer_id: customer_payment.customer_id, user_id: Current.business_owner.id, target_view: Customer::DASHBOARD_TARGET_VIEWS[:payments]), alert: outcome.errors.full_messages.to_sentence
    else
      redirect_to lines_user_bot_customers_path(business_owner_id: Current.business_owner.id, customer_id: customer_payment.customer_id, user_id: Current.business_owner.id, target_view: Customer::DASHBOARD_TARGET_VIEWS[:payments])
    end

  end

  private

  def set_customer
    if compat_read_enabled?
      return
    end

    @customer = Current.business_owner.customers.contact_groups_scope(current_user_staff).find(params[:customer_id])
  end
end

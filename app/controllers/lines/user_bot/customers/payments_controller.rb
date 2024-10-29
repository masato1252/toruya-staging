# frozen_string_literal: true

class Lines::UserBot::Customers::PaymentsController < Lines::UserBotDashboardController
  before_action :set_customer, only: [:index]

  def index
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
    @customer = Current.business_owner.customers.contact_groups_scope(current_user_staff).find(params[:customer_id])
  end
end

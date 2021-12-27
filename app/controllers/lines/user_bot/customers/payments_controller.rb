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

  private

  def set_customer
    @customer = super_user.customers.contact_groups_scope(current_user_staff).find(params[:customer_id])
  end
end

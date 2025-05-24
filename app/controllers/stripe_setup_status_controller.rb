class StripeSetupStatusController < ApplicationController
  def show
    setup_intent_id = params[:setup_intent_id]

    begin
      setup_intent = if params[:business_owner_id]
        # User-Bot payments
        Stripe::SetupIntent.retrieve(
          setup_intent_id,
          stripe_account: User.find(params[:business_owner_id]).stripe_provider.uid
        )
      elsif params[:type] == 'customer_change_card'
        # Customer payments - need to find customer by current session or other means
        customer = Customer.find(session[:customer_id])
        Stripe::SetupIntent.retrieve(
          setup_intent_id,
          stripe_account: customer.user.stripe_provider.uid
        )
      else
        # Default case
        Stripe::SetupIntent.retrieve(setup_intent_id)
      end

      case setup_intent.status
      when 'succeeded'
        render json: { status: 'succeeded' }
      when 'requires_action', 'requires_payment_method', 'requires_confirmation'
        render json: {
          status: setup_intent.status,
          client_secret: setup_intent.client_secret
        }
      when 'processing'
        render json: { status: 'processing' }
      when 'canceled'
        render json: { status: 'failed', error: 'Setup was canceled' }
      else
        render json: { status: 'failed', error: 'Setup failed' }
      end
    rescue Stripe::StripeError => e
      render json: { status: 'failed', error: e.message }, status: :unprocessable_entity
    end
  end
end
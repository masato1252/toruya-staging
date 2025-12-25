class StripePaymentStatusController < ApplicationController
  def show
    case params[:type]
    when 'subscription'
      handle_subscription_status
    else
      handle_payment_intent_status
    end
  end

  private

  def handle_payment_intent_status
    payment_intent_id = params[:payment_intent_id]

    begin
      payment_intent =
        if params[:business_owner_id]
          Stripe::PaymentIntent.retrieve(
            payment_intent_id,
            stripe_account: User.find(params[:business_owner_id]).stripe_provider.uid
          )
        else
          Stripe::PaymentIntent.retrieve(payment_intent_id)
        end

      case payment_intent.status
      when 'succeeded'
        render json: { status: 'succeeded' }
      when 'requires_action', 'requires_payment_method', 'requires_confirmation'
        render json: {
          status: payment_intent.status,
          client_secret: payment_intent.client_secret
        }
      when 'processing'
        render json: { status: 'processing' }
      when 'canceled'
        render json: { status: 'failed', error: 'Payment was canceled' }
      when 'failed'
        # PaymentIntentのlast_payment_errorからエラー情報を取得
        last_payment_error = payment_intent.last_payment_error
        render json: { 
          status: 'failed', 
          error: 'Payment failed',
          last_payment_error: last_payment_error ? {
            code: last_payment_error.code,
            message: last_payment_error.message
          } : nil
        }
      else
        render json: { status: 'failed', error: 'Payment failed' }
      end
    rescue Stripe::StripeError => e
      render json: { status: 'failed', error: e.message }, status: :unprocessable_entity
    end
  end

  def handle_subscription_status
    stripe_subscription_id = params[:stripe_subscription_id]

    begin
      if params[:business_owner_id]
        subscription = Stripe::Subscription.retrieve(
          stripe_subscription_id,
          stripe_account: User.find(params[:business_owner_id]).stripe_provider.uid
        )
      else
        subscription = Stripe::Subscription.retrieve(stripe_subscription_id)
      end

      # Manually retrieve latest invoice and payment intent if needed
      if subscription.status == 'incomplete' && subscription.latest_invoice
        latest_invoice = Stripe::Invoice.retrieve(
          subscription.latest_invoice,
          stripe_account: params[:business_owner_id] ? User.find(params[:business_owner_id]).stripe_provider.uid : nil
        )
        payment_intent = latest_invoice.payment_intent ?
          Stripe::PaymentIntent.retrieve(
            latest_invoice.payment_intent,
            stripe_account: params[:business_owner_id] ? User.find(params[:business_owner_id]).stripe_provider.uid : nil
          ) : nil
      end

      case subscription.status
      when 'active'
        render json: { status: 'succeeded' }
      when 'incomplete'
        if payment_intent
          case payment_intent.status
          when 'requires_action', 'requires_payment_method', 'requires_confirmation'
            render json: {
              status: 'requires_action',
              client_secret: payment_intent.client_secret,
              stripe_subscription_id: subscription.id
            }
          when 'processing'
            render json: { status: 'processing' }
          else
            render json: { status: 'failed', error: 'Payment incomplete' }
          end
        else
          render json: { status: 'failed', error: 'No payment intent found' }
        end
      when 'incomplete_expired'
        render json: { status: 'failed', error: 'Subscription expired' }
      when 'past_due'
        render json: { status: 'failed', error: 'Payment past due' }
      else
        render json: { status: 'failed', error: 'Subscription failed' }
      end
    rescue Stripe::StripeError => e
      render json: { status: 'failed', error: e.message }, status: :unprocessable_entity
    end
  end

end
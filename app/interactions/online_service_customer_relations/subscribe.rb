# frozen_string_literal: true

class OnlineServiceCustomerRelations::Subscribe < ActiveInteraction::Base
  include StripePaymentMethodHandler
  object :relation, class: OnlineServiceCustomerRelation
  string :stripe_subscription_id, default: nil
  string :payment_method_id, default: nil

  def execute
    price_details = relation.price_details.first

    if relation.payment_legal_to_access? && stripe_subscription_active?
      return relation
    end

    begin
      if stripe_subscription_id
        # 3DS completed, fetch the existing subscription
        stripe_subscription = Stripe::Subscription.retrieve(
          stripe_subscription_id,
          stripe_account: customer.user.stripe_provider.uid
        )
      else
        # Delete existing subscription if any
        if relation.stripe_subscription_id
          compose(
            StripeSubscriptions::Delete,
            stripe_subscription_id: relation.stripe_subscription_id,
            stripe_account: relation.customer.user.stripe_provider.uid
          )
        end

        # Get selected payment method using shared logic
        selected_payment_method = get_selected_payment_method(
          customer.stripe_customer_id,
          payment_method_id,
          customer.user.stripe_provider.uid
        )

        subscription_params = {
          customer: customer.stripe_customer_id,
          items: [
            { price: price_details.stripe_price_id },
          ],
          metadata: {
            relation: relation.id,
            customer_id: customer.id,
            customer_name: customer.name,
            service_id: relation.online_service_id
          },
          # Important: Set payment_behavior to handle 3DS properly
          payment_behavior: 'default_incomplete',
          payment_settings: {
            save_default_payment_method: 'on_subscription',
            payment_method_types: ['card']
          },
          expand: ['latest_invoice.payment_intent']
        }

        # Add specific payment method if available
        if selected_payment_method.present?
          subscription_params[:default_payment_method] = selected_payment_method
        end

        # Create new subscription
        stripe_subscription = Stripe::Subscription.create(
          subscription_params,
          stripe_account: customer.user.stripe_provider.uid
        )
      end

      relation.stripe_subscription_id = stripe_subscription.id

      # Handle different subscription statuses
      case stripe_subscription.status
      when 'active'
        # Payment succeeded immediately
        relation.paid_payment_state!
      when 'incomplete'
        # Check if 3DS is required
        payment_intent = stripe_subscription.latest_invoice.payment_intent

        if payment_intent && ['requires_action', 'requires_payment_method', 'requires_confirmation', "requires_source", "processing", "requires_source_action"].include?(payment_intent.status)
          # 3DS verification required
          errors.add(:relation, :requires_action, client_secret: payment_intent.client_secret, stripe_subscription_id: stripe_subscription.id)
          relation.incomplete_payment_state!
        else
          # Other incomplete status
          errors.add(:relation, :subscription_incomplete, client_secret: payment_intent.client_secret, stripe_subscription_id: stripe_subscription.id)
        end
      when 'incomplete_expired'
        errors.add(:relation, :subscription_expired, client_secret: payment_intent.client_secret, stripe_subscription_id: stripe_subscription.id)
      else
        # Other statuses like 'trialing', 'past_due', etc.
        relation.paid_payment_state!
      end

    rescue Stripe::CardError => error
      errors.add(:relation, :card_error, message: error.message)
      Rollbar.error(error, relation_id: relation.id)
    rescue Stripe::StripeError => error
      errors.add(:relation, :stripe_error, message: error.message)
      Rollbar.error(error, relation_id: relation.id)
    rescue => e
      Rollbar.error(e)
      errors.add(:relation, :something_wrong)
    end

    relation
  end

  private

  def customer
    @customer ||= relation.customer
  end

  def stripe_subscription_active?
    relation.stripe_subscription_id &&
      Stripe::Subscription.retrieve(relation.stripe_subscription_id, { stripe_account: customer.user.stripe_provider.uid }).status == STRIPE_SUBSCRIPTION_STATUS[:active]
  rescue Stripe::InvalidRequestError => e
    Rollbar.error(e)

    false
  end
end

# frozen_string_literal: true

class OnlineServiceCustomerRelations::Subscribe < ActiveInteraction::Base
  object :relation, class: OnlineServiceCustomerRelation
  string :stripe_subscription_id, default: nil

  def execute
    price_details = relation.price_details.first

    relation.with_lock do
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

          # Create new subscription
          stripe_subscription = Stripe::Subscription.create(
            {
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
            },
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

          if payment_intent && payment_intent.status == 'requires_action'
            # 3DS verification required
            errors.add(:relation, :requires_action, client_secret: payment_intent.client_secret, stripe_subscription_id: stripe_subscription.id)
          elsif payment_intent && payment_intent.status == 'requires_payment_method'
            # Payment method failed
            errors.add(:relation, :payment_failed, client_secret: payment_intent.client_secret, stripe_subscription_id: stripe_subscription.id)
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

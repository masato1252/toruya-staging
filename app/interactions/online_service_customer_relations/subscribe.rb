# frozen_string_literal: true

class OnlineServiceCustomerRelations::Subscribe < ActiveInteraction::Base
  object :relation, class: OnlineServiceCustomerRelation

  def execute
    price_details = relation.price_details.first

    relation.with_lock do
      if relation.legal_to_access? && stripe_subscription_active?
        return relation
      end

      begin
        if relation.stripe_subscription_id
          Stripe::Subscription.delete(
            relation.stripe_subscription_id,
            {},
            { stripe_account: customer.user.stripe_provider.uid }
          )
        end

        stripe_subscription = Stripe::Subscription.create(
          {
            customer: customer.stripe_customer_id,
            items: [
              { price: price_details.stripe_price_id },
            ],
          },
          stripe_account: customer.user.stripe_provider.uid
        )

        relation.stripe_subscription_id = stripe_subscription.id
        # When you create a subscription with collection_method=charge_automatically,
        # the first invoice is finalized as part of the request. The payment_behavior parameter determines the exact behavior of the initial payment.
        relation.paid_payment_state!
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

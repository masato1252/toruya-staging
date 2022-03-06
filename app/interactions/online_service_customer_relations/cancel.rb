# frozen_string_literal: true

require "slack_client"

# user unsubscribe a customer
# customer could not use until the end of the period(not immediately, active, but change expire_at)
class OnlineServiceCustomerRelations::Cancel < ActiveInteraction::Base
  object :relation, class: OnlineServiceCustomerRelation
  boolean :end_of_period, default: true

  def execute
    relation.with_lock do
      if (relation.pending? || relation.inactive?) && stripe_subscription_canceled?
        return relation
      end

      begin
        canceled_stripe_subscription = Stripe::Subscription.delete(
          relation.stripe_subscription_id,
          {},
          { stripe_account: relation.customer.user.stripe_provider.uid }
        )

        relation.stripe_subscription_id = nil
        relation.expire_at = Time.at(canceled_stripe_subscription.current_period_end)
        relation.canceled_payment_state!
      rescue => e
        errors.add(:relation, :something_wrong)
      end

      relation
    end
  end

  private

  def stripe_subscription_canceled?
    relation.stripe_subscription_id &&
      Stripe::Subscription.retrieve(relation.stripe_subscription_id, { stripe_account: relation.customer.user.stripe_provider.uid }).status == STRIPE_SUBSCRIPTION_STATUS[:canceled]
  rescue Stripe::InvalidRequestError => e
    Rollbar.error(e)

    true
  end
end

# frozen_string_literal: true

require "slack_client"

# user unsubscribe a customer
# customer could not use until the end of the period(not immediately, active, but change expire_at)
class OnlineServiceCustomerRelations::Unsubscribe < ActiveInteraction::Base
  object :relation, class: OnlineServiceCustomerRelation

  def execute
    relation.with_lock do
      if relation.inactive? && stripe_subscription_canceled?
        return relation
      end

      begin
        canceled_stripe_subscription = Stripe::Subscription.delete(relation.stripe_subscription_id)

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
    relation.stripe_subscription_id && Stripe::Subscription.retrieve(relation.stripe_subscription_id).status == STRIPE_SUBSCRIPTION_STATUS[:canceled]
  end
end

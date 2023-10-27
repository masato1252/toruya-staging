# frozen_string_literal: true

require "slack_client"

# user unsubscribe a customer
# customer could not use until the end of the period(not immediately, active, but change expire_at)
class OnlineServiceCustomerRelations::Cancel < ActiveInteraction::Base
  object :relation, class: OnlineServiceCustomerRelation
  boolean :end_of_period, default: true

  def execute
    relation.with_lock do
      if !relation.payment_legal_to_access? && stripe_subscription_canceled?
        return relation
      end

      begin
        canceled_stripe_subscription = compose(
          StripeSubscriptions::Delete,
          stripe_subscription_id: relation.stripe_subscription_id,
          stripe_account: relation.customer.user.stripe_provider.uid
        )

        relation.stripe_subscription_id = nil
        # when subscription was canceled from stripe side, there is no canceled_stripe_subscription
        relation.expire_at = canceled_stripe_subscription.try(:canceled_stripe_subscription) ? Time.at(canceled_stripe_subscription.current_period_end) : Time.current
        relation.canceled_payment_state!

        # Only bundler had bundled_service_relations
        relation.bundled_service_relations.each do |bundled_service_relation|
          OnlineServiceCustomerRelations::ReconnectBestContract.run(relation: bundled_service_relation)
        end
      rescue => e
        errors.add(:relation, :something_wrong)
      end

      relation
    end
  end

  private

  def stripe_subscription_canceled?
    compose(
      StripeSubscriptions::IsCanceled,
      stripe_subscription_id: relation.stripe_subscription_id,
      stripe_account: relation.customer.user.stripe_provider.uid
    )
  end
end

# frozen_string_literal: true

require "slack_client"

# https://dashboard.stripe.com/settings/billing/automatic
# customer be unsubscribe because of failure payment, customer could not use immediately
class OnlineServiceCustomerRelations::Unsubscribe < ActiveInteraction::Base
  object :relation, class: OnlineServiceCustomerRelation

  def execute
    relation.with_lock do
      if !relation.payment_legal_to_access? && stripe_subscription_canceled?
        return relation
      end

      begin
        compose(
          StripeSubscriptions::Delete,
          stripe_subscription_id: relation.stripe_subscription_id,
          stripe_account: relation.customer.user.stripe_provider.uid
        )

        relation.payment_state = :failed
        relation.stripe_subscription_id = nil
        relation.pending!

        relation.bundled_service_relations.each do |bundled_service_relation|
          compose(OnlineServiceCustomerRelations::ReconnectBestContract, relation: bundled_service_relation)
        end

        relation
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

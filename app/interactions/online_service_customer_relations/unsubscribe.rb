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
        relation.pending!
        relation

        if relation.online_service.bundler?
          relation.bundled_service_relations.each do |bundled_service_relation|
            # only stop subscription, forever still forever
            bundled_service_relation.pending! if bundled_service_relation.bundled_service&.subscription
          end
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

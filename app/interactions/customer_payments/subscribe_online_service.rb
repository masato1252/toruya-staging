# frozen_string_literal: true

class CustomerPayments::SubscribeOnlineService < ActiveInteraction::Base
  object :online_service_customer_relation
  string :stripe_subscription_id, default: nil

  def execute
    subscribe_outcome = OnlineServiceCustomerRelations::Subscribe.run(
      relation: online_service_customer_relation,
      stripe_subscription_id: stripe_subscription_id
    )

    if subscribe_outcome.valid?
      outcome =
        if product.bundler?
          Sales::OnlineServices::ApproveBundlerService.run(relation: online_service_customer_relation)
        else
          Sales::OnlineServices::Approve.run(relation: online_service_customer_relation)
        end

        errors.merge!(outcome.errors)
    else
      errors.merge!(subscribe_outcome.errors)

      online_service_customer_relation.failed_payment_state!
    end
  end

  private

  def product
    online_service_customer_relation.online_service
  end
end

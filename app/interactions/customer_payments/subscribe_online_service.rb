# frozen_string_literal: true

class CustomerPayments::SubscribeOnlineService < ActiveInteraction::Base
  object :online_service_customer_relation
  string :stripe_subscription_id, default: nil
  string :payment_method_id, default: nil

  def execute
    subscribe_outcome = OnlineServiceCustomerRelations::Subscribe.run(
      relation: online_service_customer_relation,
      stripe_subscription_id: stripe_subscription_id,
      payment_method_id: payment_method_id
    )

    if subscribe_outcome.valid?
      outcome =
        if product.bundler?
          Sales::OnlineServices::ApproveBundlerService.run(relation: online_service_customer_relation)
        else
          Sales::OnlineServices::Approve.run(relation: online_service_customer_relation)
        end

        if outcome.valid?
          online_service_customer_relation.paid_payment_state!
        else
          errors.merge!(outcome.errors)
        end
    else
      errors.merge!(subscribe_outcome.errors)

      online_service_customer_relation.failed_payment_state! if !online_service_customer_relation.incomplete_payment_state?
    end
  end

  private

  def product
    online_service_customer_relation.online_service
  end
end

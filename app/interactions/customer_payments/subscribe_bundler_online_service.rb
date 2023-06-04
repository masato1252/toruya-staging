# frozen_string_literal: true

require "slack_client"

class CustomerPayments::SubscribeBundlerOnlineService < ActiveInteraction::Base
  object :online_service_customer_relation

  def execute
    outcome = OnlineServiceCustomerRelations::Subscribe.run(relation: online_service_customer_relation)

    if outcome.valid?
      bundler_outcome = Sales::OnlineServices::ApproveBundlerService.run(relation: online_service_customer_relation)

      errors.merge!(bundler_outcome.errors)
    else
      errors.merge!(outcome.errors)

      online_service_customer_relation.failed_payment_state!
    end
  end
end

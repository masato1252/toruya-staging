# frozen_string_literal: true

require "slack_client"

class CustomerPayments::SubscribeOnlineService < ActiveInteraction::Base
  object :online_service_customer_relation

  def execute
    if compose(OnlineServiceCustomerRelations::Subscribe, relation: online_service_customer_relation)
      Sales::OnlineServices::Approve.run(relation: online_service_customer_relation)
    else
      online_service_customer_relation.failed_payment_state!
    end
  end
end

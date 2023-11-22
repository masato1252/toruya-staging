# frozen_string_literal: true

class SubscriptionCheckingJob < ApplicationJob
  queue_as :low_priority

  def perform(event, subscription_id)
    unless OnlineServiceCustomerRelation.find_by(stripe_subscription_id: subscription_id)
      Rollbar.error("Unexpected subscription", { event: event })

      SlackClient.send(channel: 'development', text: "There is unexpected subscription #{subscription_id}, check is a legal toruya subscription or not, if it is a legal subscription, need to resend webhook manually in https://dashboard.stripe.com/webhooks/")
    end
  end
end

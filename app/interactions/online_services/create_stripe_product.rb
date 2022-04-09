# frozen_string_literal: true

module OnlineServices
  class CreateStripeProduct < ActiveInteraction::Base
    object :online_service

    def execute
      Stripe::Product.create(
        { name: online_service.name },
        stripe_account: online_service.user.stripe_provider.uid
      )
    rescue => e
      Rollbar.error(e)
      errors.add(:online_service, :something_wrong)
    end
  end
end

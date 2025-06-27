# frozen_string_literal: true

module StripeEvents
  class Handler < ActiveInteraction::Base
    object :event, class: Stripe::Event

    def execute
      case event.type
      when 'invoice.payment_succeeded'
        Rollbar.info(event.type, { event: event })
        compose(StripeEvents::PaymentSucceed, event: event)
      when 'invoice.payment_failed'
        Rollbar.error(event.type, { event: event })

        compose(StripeEvents::PaymentFailed, event: event)
      when 'invoice.upcoming'
        compose(StripeEvents::PaymentUpcoming, event: event)
      else
        Rollbar.error(event.type, { event: event })
      end
    end
  end
end

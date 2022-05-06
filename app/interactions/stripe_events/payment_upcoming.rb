# frozen_string_literal: true

module StripeEvents
  class PaymentUpcoming < ActiveInteraction::Base
    # https://stripe.com/docs/api/events/types#event_types-invoice.upcoming
    object :event, class: Stripe::Event

    def execute
      data_object = event.data.object
      return unless data_object.subscription

      relation = OnlineServiceCustomerRelation.find_by(stripe_subscription_id: data_object.subscription)
      unless relation
        Rollbar.error("Unexpected subscription", {
          event: event.as_json
        })
        return
      end

      Notifiers::Customers::OnlineServices::ChargeReminder.perform_later(
        receiver: relation.customer,
        online_service_customer_relation: relation,
        online_service_customer_price: relation.price_details.first,
        charge_at: Time.at(data_object.period_end)
      )
    end
  end
end

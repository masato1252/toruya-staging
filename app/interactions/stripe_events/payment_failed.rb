# frozen_string_literal: true

module StripeEvents
  class PaymentFailed < ActiveInteraction::Base
    # https://stripe.com/docs/api/invoices/object
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

      relation = compose(OnlineServiceCustomerRelations::Unsubscribe, relation: relation)

      relation.with_lock do
        customer = relation.customer

        payment = customer.customer_payments.new(
          product: relation,
          amount_cents: data_object.total,
          amount_currency: Money.default_currency.iso_code,
          charge_at: Time.current,
          expired_at: nil,
          manual: false,
          order_id: data_object.id,
          stripe_charge_details: event.as_json
        )
        payment.processor_failed!

        # https://stripe.com/docs/api/invoices/object#invoice_object-billing_reason
        failed_charge_notification(payment)

        payment
      end
    end

    private

    def failed_charge_notification(payment)
      Notifiers::Users::CustomerPayments::ChargeFailedToOwner.run(
        receiver: payment.product.customer.user,
        customer_payment: payment
      )

      Notifiers::Customers::CustomerPayments::ChargeFailedToCustomer.run(
        receiver: payment.product.customer,
        customer_payment: payment
      )
    end
  end
end

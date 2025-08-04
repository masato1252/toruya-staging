# frozen_string_literal: true

module StripeEvents
  class PaymentSucceed < ActiveInteraction::Base
    # https://stripe.com/docs/api/invoices/object
    object :event, class: Stripe::Event

    def execute
      data_object = event.data.object
      return unless data_object.subscription

      relation = OnlineServiceCustomerRelation.find_by(stripe_subscription_id: data_object.subscription)
      unless relation
        SubscriptionCheckingJob.set(wait_until: 10.minutes.from_now).perform_later(event.as_json, data_object.subscription) if Rails.configuration.x.env.production?

        errors.add(:event, :unexpected_subscription)
        return
      end

      customer = relation.customer

      stripe_subscription = Stripe::Subscription.retrieve(
        relation.stripe_subscription_id,
        { stripe_account: customer.user.stripe_provider.uid }
      )

      relation.with_lock do
        if existing_payment = relation.customer_payments.where(order_id: data_object.id).completed.take
          Rollbar.error("Unexpected event", {
            event: event.as_json,
            backtrace: caller
          })

          return existing_payment
        end

        # https://stripe.com/docs/api/invoices/object#invoice_object-billing_reason
        if ['subscription_cycle', 'subscription_create'].include?(data_object['billing_reason'])
          payment = customer.customer_payments.new(
            product: relation,
            amount_cents: data_object.total,
            amount_currency: customer.user.currency,
            charge_at: Time.current,
            expired_at: Time.at(stripe_subscription.current_period_end),
            manual: false,
            order_id: data_object.id,
            stripe_charge_details: event.as_json
          )
          relation.update(expire_at: Time.at(stripe_subscription.current_period_end) + 1.day, payment_state: :paid)
          payment.completed!

          if relation.inactive? || relation.pending?
            ::Sales::OnlineServices::Approve.run!(relation: relation)

            if relation.online_service.bundler?
              ::Sales::OnlineServices::ApproveBundlerService.run!(relation: relation)
            end
          end
        end

        if data_object['billing_reason'] == 'subscription_cycle'
          Notifiers::Customers::CustomerPayments::NotFirstTimeChargeSuccessfully.run(
            receiver: customer,
            customer_payment: payment
          )
        end

        # https://github.com/stripe-samples/subscription-use-cases/blob/37134bdd22736165371535e1cc5a4c5fef699f08/fixed-price-subscriptions/server/ruby/server.rb#L204-L218
        if data_object['billing_reason'] == 'subscription_create'
          # The subscription automatically activates after successful payment
          # Set the payment method used to pay the first invoice
          # as the default payment method for that subscription
          payment_intent_id = data_object['payment_intent']

          # Retrieve the payment intent used to pay the subscription
          payment_intent = Stripe::PaymentIntent.retrieve(
            payment_intent_id,
            { stripe_account: customer.user.stripe_provider.uid }
          )

          # Only update default_payment_method if subscription is not canceled (active, trialing, unpaid, etc.)
          if %w[active trialing unpaid past_due incomplete incomplete_expired].include?(stripe_subscription.status)
            Stripe::Subscription.update(
              relation.stripe_subscription_id,
              { default_payment_method: payment_intent.payment_method },
              { stripe_account: customer.user.stripe_provider.uid }
            )
          else
            Rollbar.warn("Skip updating default_payment_method for canceled subscription", {
              subscription_id: relation.stripe_subscription_id,
              status: stripe_subscription.status,
              event: event.as_json
            })
          end
        end

        if Rails.configuration.x.env.production?
          HiJob.set(wait_until: 5.minutes.from_now).perform_later("[OK] 🎉Membership: Sale Page #{Rails.application.routes.url_helpers.sale_page_url(relation.sale_page.slug)} customer_id: #{relation.customer.id} Stripe charge💰")
        end

        payment
      end
    end
  end
end

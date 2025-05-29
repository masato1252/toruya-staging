# frozen_string_literal: true

FactoryBot.define do
  factory :online_service_customer_relation do
    association :customer
    sale_page { FactoryBot.create(:sale_page, :online_service) }
    online_service { sale_page.product }
    current { true }

    trait :assignment do
      sale_page { nil }
    end

    trait :free do
      payment_state { "free" }
      permission_state { "active" }
      product_details {
        OnlineServiceCustomerProductDetails.build(
          sale_page: sale_page,
          payment_type: SalePage::PAYMENTS[:free]
        )
      }
    end

    trait :paid do
      payment_state { "paid" }
      permission_state { "active" }
      paid_at { Time.current }
    end

    trait :one_time_payment do
      sale_page { FactoryBot.create(:sale_page, :online_service, :one_time_payment, user: customer.user) }
      product_details {
        OnlineServiceCustomerProductDetails.build(
          sale_page: sale_page,
          payment_type: SalePage::PAYMENTS[:one_time]
        )
      }
    end

    trait :multiple_times_payment do
      sale_page { FactoryBot.create(:sale_page, :online_service, :multiple_times_payment, user: customer.user) }
      product_details {
        OnlineServiceCustomerProductDetails.build(
          sale_page: sale_page,
          payment_type: SalePage::PAYMENTS[:multiple_times]
        )
      }
    end

    trait :monthly_payment do
      sale_page { FactoryBot.create(:sale_page, :recurring_payment, user: customer.user) }
      product_details {
        OnlineServiceCustomerProductDetails.build(
          sale_page: sale_page,
          payment_type: SalePage::PAYMENTS[:month]
        )
      }
    end

    trait :yearly_payment do
      sale_page { FactoryBot.create(:sale_page, :recurring_payment, user: customer.user) }
      product_details {
        OnlineServiceCustomerProductDetails.build(
          sale_page: sale_page,
          payment_type: SalePage::PAYMENTS[:month]
        )
      }
    end

    trait :canceled do
      payment_state { "canceled" }
      permission_state { "pending" }
    end

    trait :expired do
      permission_state { "active" }
      expire_at { 1.day.ago }
    end

    trait :stripe_subscribed do
      stripe_subscription_id do
        # Customer should already have Stripe setup (use with_stripe: true when creating customer)
        unless customer.stripe_customer_id
          raise "Customer must have Stripe setup. Create customer with 'with_stripe: true'"
        end

        # Create the subscription
        Stripe::Subscription.create(
          {
            customer: customer.stripe_customer_id,
            items: [
              { price: sale_page.monthly_price.stripe_price_id },
            ],
          },
          stripe_account: customer.user.stripe_provider.uid
        ).id
      end
    end
  end

  trait :bundler_payment do
    product_details {
      OnlineServiceCustomerProductDetails.build(
        sale_page: sale_page,
        payment_type: SalePage::PAYMENTS[:bundler]
      )
    }
  end
end

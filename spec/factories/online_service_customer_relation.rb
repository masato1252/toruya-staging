# frozen_string_literal: true

FactoryBot.define do
  factory :online_service_customer_relation do
    association :customer
    sale_page { FactoryBot.create(:sale_page, :online_service) }
    online_service { sale_page.product }

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
      sale_page { FactoryBot.create(:sale_page, :online_service, :one_time_payment) }
      product_details {
        OnlineServiceCustomerProductDetails.build(
          sale_page: sale_page,
          payment_type: SalePage::PAYMENTS[:one_time]
        )
      }
    end

    trait :multiple_times_payment do
      sale_page { FactoryBot.create(:sale_page, :online_service, :multiple_times_payment) }
      product_details {
        OnlineServiceCustomerProductDetails.build(
          sale_page: sale_page,
          payment_type: SalePage::PAYMENTS[:multiple_times]
        )
      }
    end

    trait :canceled do
      payment_state { "canceled" }
      permission_state { "pending" }
    end
  end
end

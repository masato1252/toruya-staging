# frozen_string_literal: true

FactoryBot.define do
  factory :online_service_customer_relation do
    association :customer
    sale_page { FactoryBot.create(:sale_page, :online_service) }
    online_service { sale_page.product }

    trait :free do
      payment_state { "free" }
      permission_state { "active" }
    end

    trait :paid do
      payment_state { "paid" }
      permission_state { "active" }
      paid_at { Time.current }
    end
  end
end

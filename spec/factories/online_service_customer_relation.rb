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
  end
end

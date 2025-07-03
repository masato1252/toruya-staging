# frozen_string_literal: true

FactoryBot.define do
  factory :customer_payment do
    association :customer
    product { FactoryBot.create(:online_service_customer_relation, customer: customer) }
    amount { Money.new(1000) }
    provider { AccessProvider.providers[:stripe_connect] }

    trait :active do
      state { :active }
    end

    trait :completed do
      state { :completed }
    end

    trait :processor_failed do
      state { :processor_failed }
    end
  end
end

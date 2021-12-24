# frozen_string_literal: true

FactoryBot.define do
  factory :customer_payment do
    association :customer
    product { FactoryBot.create(:online_service_customer_relation, customer: customer) }
    amount { Money.new(1000) }

    trait :completed do
      state { :completed }
    end
  end
end

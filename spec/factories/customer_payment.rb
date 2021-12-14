# frozen_string_literal: true

FactoryBot.define do
  factory :customer_payment do
    association :customer
    product { FactoryBot.create(:sale_page, user: customer.user) }
    amount { Money.new(1000) }

    trait :completed do
      state { :completed }
    end
  end
end

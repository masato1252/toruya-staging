# frozen_string_literal: true

FactoryBot.define do
  factory :ahoy_visit, class: Ahoy::Visit do
    association :user

    trait :booking_page do
      product { FactoryBot.create(:booking_page, user: user) }
    end
  end
end

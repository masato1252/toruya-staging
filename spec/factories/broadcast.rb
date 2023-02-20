# frozen_string_literal: true

FactoryBot.define do
  factory :broadcast do
    association :user
    content { Faker::Lorem.word }
    query { {} }
    query_type { "online_service" }

    trait :draft do
      state { :draft }
    end

    trait :active do
      state { :active }
    end

    trait :final do
      state { :final }
    end
  end
end

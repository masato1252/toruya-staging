# frozen_string_literal: true

FactoryBot.define do
  factory :access_provider do
    association :user
    access_token { SecureRandom.uuid }
    refresh_token { SecureRandom.uuid }

    trait :stripe do
      provider { "stripe_connect" }
    end

    trait :google do
      provider { "google_oauth2" }
    end
  end
end

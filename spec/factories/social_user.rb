# frozen_string_literal: true

FactoryBot.define do
  factory :social_user do
    association :user
    social_service_user_id { SecureRandom.hex }
    social_user_name { Faker::Lorem.word }
  end
end

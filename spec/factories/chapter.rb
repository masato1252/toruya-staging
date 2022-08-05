# frozen_string_literal: true

FactoryBot.define do
  factory :chapter do
    association :online_service
    name { Faker::Lorem.word }
  end
end

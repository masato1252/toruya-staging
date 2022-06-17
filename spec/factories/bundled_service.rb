# frozen_string_literal: true

FactoryBot.define do
  factory :bundled_service do
    association :bundler_service
    association :online_service
  end
end

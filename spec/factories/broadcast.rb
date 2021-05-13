# frozen_string_literal: true

FactoryBot.define do
  factory :broadcast do
    association :user
    content { Faker::Lorem.word }
  end
end

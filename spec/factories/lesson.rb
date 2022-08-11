# frozen_string_literal: true

FactoryBot.define do
  factory :lesson do
    association :chapter
    name { Faker::Lorem.word }
    solution_type { "video" }
  end
end

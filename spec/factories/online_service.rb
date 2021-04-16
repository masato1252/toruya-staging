# frozen_string_literal: true

FactoryBot.define do
  factory :online_service do
    association :user
    name { Faker::Lorem.word }
    goal_type { "collection" }
    solution_type { "video" }
    company { FactoryBot.create(:profile, user: user) }
    slug { SecureRandom.hex  }
  end
end

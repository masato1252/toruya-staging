# frozen_string_literal: true

FactoryBot.define do
  factory :episode do
    association :online_service
    user { online_service.user }
    content_url { "url" }
    name { "episode name" }
    solution_type { "video" }
  end
end

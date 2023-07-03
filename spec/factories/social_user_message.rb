# frozen_string_literal: true

FactoryBot.define do
  factory :social_user_message do
    association :social_user
    raw_content { Faker::Lorem.word }
    sent_at { Time.current }
  end
end

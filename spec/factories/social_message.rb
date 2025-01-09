# frozen_string_literal: true

FactoryBot.define do
  factory :social_message do
    association :social_customer
    social_account { FactoryBot.create(:social_account, user: social_customer.user) }
    raw_content { Faker::Lorem.word }
    sent_at { Time.current }

    trait :customer do
      message_type { :customer }
    end
  end
end

# frozen_string_literal: true

FactoryBot.define do
  factory :social_customer do
    association :user
    association :social_account
    customer { FactoryBot.create(:customer, user: user) }
    social_user_id { SecureRandom.hex }
    social_user_name { Faker::Lorem.word }
    social_rich_menu_key { SecureRandom.hex }

    trait :bot do
      conversation_state { SocialCustomer.conversation_states[:bot] }
    end

    trait :one_on_one do
      conversation_state { SocialCustomer.conversation_states[:one_on_one] }
    end

    trait :is_owner do
      is_owner { true }
    end
  end
end

FactoryBot.define do
  factory :social_customer do
    association :user
    association :social_account
    customer { FactoryBot.create(:customer, user: user) }
    social_user_id { SecureRandom.hex }
    social_user_name { Faker::Lorem.word }

    trait :bot do
      conversation_state { SocialCustomer.conversation_states[:bot] }
    end

    trait :one_on_one do
      conversation_state { SocialCustomer.conversation_states[:one_on_one] }
    end
  end
end

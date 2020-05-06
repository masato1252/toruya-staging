FactoryBot.define do
  factory :social_customer do
    association :user
    association :social_account
    social_user_id { SecureRandom.hex }
    social_user_name { Faker::Lorem.word }
  end
end

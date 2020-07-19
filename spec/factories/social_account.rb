FactoryBot.define do
  factory :social_account do
    association :user
    channel_id { SecureRandom.hex }
    channel_token { SecureRandom.hex }
    channel_secret { SecureRandom.hex }
    label { Faker::Lorem.word }
    basic_id { "@#{Faker::IDNumber.valid}" }
  end
end

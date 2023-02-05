# frozen_string_literal: true

FactoryBot.define do
  factory :social_account do
    association :user
    channel_id { SecureRandom.hex }
    channel_token { MessageEncryptor.encrypt(SecureRandom) }
    channel_secret { MessageEncryptor.encrypt(SecureRandom) }
    label { Faker::Lorem.word }
    basic_id { "@#{Faker::IDNumber.valid}" }
    login_channel_id { SecureRandom.hex }
    login_channel_secret { MessageEncryptor.encrypt(SecureRandom) }
  end
end

# frozen_string_literal: true

FactoryBot.define do
  factory :social_account do
    association :user
    login_channel_id { SecureRandom.hex }
    login_channel_secret { MessageEncryptor.encrypt(SecureRandom.hex) }
    channel_id { SecureRandom.hex }
    channel_token {  MessageEncryptor.encrypt(SecureRandom.hex) }
    channel_secret {  MessageEncryptor.encrypt(SecureRandom.hex) }
    label { Faker::Lorem.word }
    sequence(:basic_id) { |n| "@#{n}123" }
  end
end

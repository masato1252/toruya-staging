FactoryBot.define do
  factory :social_message do
    association :social_account
    association :social_customer
    raw_content { Faker::Lorem.word }
  end
end

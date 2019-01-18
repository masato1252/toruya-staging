FactoryBot.define do
  factory :profile do
    association :user
    sequence(:first_name) { |n| "first_name#{n}" }
    sequence(:last_name) { |n| "last_name#{n}" }
    sequence(:phonetic_first_name) { |n| "phonetic_first_name#{n}" }
    sequence(:phonetic_last_name) { |n| "phonetic_last_name#{n}" }
    sequence(:zip_code) { |n| "zip_code#{n}" }
    sequence(:address) { |n| "address#{n}" }
    sequence(:phone_number) { |n| "123#{n}" }
  end
end

FactoryBot.define do
  factory :customer do
    association :user
    association :contact_group
    sequence(:last_name) { |n| "last_name-#{n}" }
    sequence(:first_name) { |n| "first_name-#{n}" }
  end
end

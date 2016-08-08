FactoryGirl.define do
  factory :user do
    sequence(:email) { |n| "foo#{n}@gmail.com" }
    password "foobar78"
  end

  factory :shop do
    association :user
    sequence(:name) { |n| "foo#{n}" }
    sequence(:shortname) { |n| "f#{n}" }
    zip_code "160-0005"
    phone_number "123456789"
    sequence(:email) { |n| "foo#{n}@gmail.com" }
    sequence(:address) { |n| "address#{n}" }
  end

  factory :custom_schedule do
  end

  factory :business_schedule do
    association :shop
    days_of_week { Date.today.wday }
    business_state "opened"
  end
end

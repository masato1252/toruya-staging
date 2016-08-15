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
    association :shop
    association :staff
  end

  factory :business_schedule do
    association :shop
    days_of_week { start_time.wday }
    business_state "opened"
  end

  factory :menu do
    association :shop
    name "foo"
    shortname "f"
  end

  factory :reservation_setting do
    association :menu
    name "foo"
    short_name "f"
  end

  factory :reservation do
    association :shop
    association :menu
    start_time { Time.zone.now }
    end_time { Time.zone.now.advance(hours: 1) }
    staff_ids { FactoryGirl.create(:staff, shop: shop).id }
    customer_ids { FactoryGirl.create(:customer, shop: shop).id }
  end

  factory :staff do
    association :shop
    name "foo"
    shortname "f"
  end

  factory :customer do
    association :shop
    last_name "last_name"
    first_name "first_name"
  end
end

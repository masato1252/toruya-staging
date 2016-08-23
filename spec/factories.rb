FactoryGirl.define do
  factory :user do
    sequence(:email) { |n| "foo#{n}@gmail.com" }
    password "foobar78"
    confirmed_at { Time.now }
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
    day_of_week { start_time.wday }
    business_state "opened"
    start_time { Time.local(2016, 8, 22, 8, 0, 0) }
    end_time { Time.local(2016, 8, 22, 19, 0, 0) }
  end

  factory :menu do
    association :shop
    sequence(:name) { |n| "menu-#{n}" }
    sequence(:shortname) { |n| "m-#{n}" }
    minutes 60
    min_staffs_number 1

    trait :lecture do
      min_staffs_number 2
      max_seat_number 3
    end

    trait :easy do
      min_staffs_number nil
    end
  end

  factory :reservation_setting do
    association :menu
    sequence(:name) { |n| "settings-#{n}" }
    sequence(:short_name) { |n| "s-#{n}" }
    day_type "business_days"

    trait :weekly do
      day_type "weekly"
      sequence(:day_of_week) { |n| n%7 }
    end

    trait :number_of_day_monthly do
      day_type "number_of_day_monthly"
      sequence(:day) { |n| n%28 }
    end

    trait :day_of_week_monthly do
      day_type "day_of_week_monthly"
      sequence(:nth_of_week) { |n| n%4 }
      sequence(:day_of_week) { |n| n%7 }
    end
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
    sequence(:name) { |n| "staff-#{n}" }
    sequence(:shortname) { |n| "s-#{n}" }
    full_time true
  end

  factory :staff_menu do
    association :staff
    association :menu
    max_customers 2
  end

  factory :customer do
    association :shop
    sequence(:last_name) { |n| "last_name-#{n}" }
    sequence(:first_name) { |n| "first_name-#{n}" }
  end
end

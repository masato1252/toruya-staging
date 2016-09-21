FactoryGirl.define do
  factory :shop_menu do
    association :shop
    association :menu
  end

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

  factory :reservation_setting_menu do
    association :reservation_setting
    association :menu
  end

  factory :menu_reservation_setting_rule do
    association :menu
    start_date { Date.today }
  end

  factory :reservation do
    association :shop
    association :menu
    start_time { Time.zone.now }
    end_time { Time.zone.now.advance(hours: 1) }
    staff_ids { FactoryGirl.create(:staff).id }
    customer_ids { [FactoryGirl.create(:customer).id] }
  end

  factory :staff_menu do
    association :staff
    association :menu
    max_customers 2
  end

  factory :shop_staff do
    association :shop
    association :staff
  end

  factory :customer do
    association :user
    sequence(:last_name) { |n| "last_name-#{n}" }
    sequence(:first_name) { |n| "first_name-#{n}" }
  end
end

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

  factory :menu do
    _user = FactoryGirl.create(:user)

    transient do
      shop FactoryGirl.create(:shop, user: _user)
    end

    user { _user }
    sequence(:name) { |n| "menu-#{n}" }
    sequence(:shortname) { |n| "m-#{n}" }
    minutes 60
    interval 10
    min_staffs_number 1

    trait :lecture do
      min_staffs_number 2
      max_seat_number 3
    end

    trait :easy do
      min_staffs_number nil
    end

    after(:create) do |menu, proxy|
      FactoryGirl.create(:shop_menu, menu: menu, shop: proxy.shop)
    end
  end

  factory :reservation_setting do
    _user = FactoryGirl.create(:user)

    user { _user }

    sequence(:name) { |n| "settings-#{n}" }
    sequence(:short_name) { |n| "s-#{n}" }
    day_type "business_days"

    transient do
      menu FactoryGirl.create(:menu, user: _user)
    end

    trait :weekly do
      day_type "weekly"
      sequence(:days_of_week) { |n| [n%7] }
    end

    trait :number_of_day_monthly do
      day_type "monthly"
      sequence(:day) { |n| n%28 }
    end

    trait :day_of_week_monthly do
      day_type "monthly"
      sequence(:nth_of_week) { |n| n%4 }
      sequence(:days_of_week) { |n| [n%7] }
    end

    after(:create) do |setting, proxy|
      FactoryGirl.create(:reservation_setting_menu, reservation_setting: setting, menu: proxy.menu)
      FactoryGirl.create(:menu_reservation_setting_rule, menu: proxy.menu)
    end
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
    customer_ids { FactoryGirl.create(:customer).id }
  end

  factory :staff do
    _user = FactoryGirl.create(:user)

    transient do
      shop FactoryGirl.create(:shop, user: _user)
    end

    user { _user }
    sequence(:last_name) { |n| "last_name-#{n}" }
    sequence(:first_name) { |n| "first_name-#{n}" }

    trait :full_time do
      after(:create) do |staff, proxy|
        FactoryGirl.create(:business_schedule, shop: proxy.shop, staff: staff, full_time: true)
      end
    end

    after(:create) do |staff, proxy|
      FactoryGirl.create(:shop_staff, staff: staff, shop: proxy.shop)
    end
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

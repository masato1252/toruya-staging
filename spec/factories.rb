FactoryGirl.define do
  factory :shop_menu do
    association :shop
    association :menu
  end

  factory :user do
    sequence(:email) { |n| "foo#{n}@gmail.com" }
    password "foobar78"
    confirmed_at { Time.zone.now }
  end

  factory :shop do
    association :user
    sequence(:name) { |n| "foo#{n}" }
    sequence(:short_name) { |n| "f#{n}" }
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
    start_time { Time.zone.local(2016, 8, 22, 8, 0, 0) }
    end_time { Time.zone.local(2016, 8, 22, 19, 0, 0) }
  end

  factory :reservation_setting_menu do
    association :reservation_setting
    association :menu
  end

  factory :menu_reservation_setting_rule do
    association :menu
    start_date { Time.zone.now.to_date }

    trait :repeating do
      repeats 2

      after(:create) do |rule|
        FactoryGirl.create(:shop_menu_repeating_date, shop: menu.shop, menu: menu)
      end
    end
  end

  factory :shop_menu_repeating_date do
    association :shop
    association :menu
    dates { [Time.zone.now.to_date, Time.zone.now.tomorrow.to_date] }
  end

  factory :reservation do
    association :shop
    association :menu
    start_time { Time.zone.now }
    end_time { Time.zone.now.advance(hours: 1) }
    staff_ids { FactoryGirl.create(:staff).id }
    customer_ids { [FactoryGirl.create(:customer).id] }
  end

  factory :rank do
    association :user
    name "Regular"
    key Rank::REGULAR_KEY
  end

  factory :category do
    association :user
    sequence(:name) { |n| "category-#{n}" }

    transient do
      menus []
    end

    after(:create) do |category, proxy|
      if proxy.menus.present?
        proxy.menus.each do |menu|
          FactoryGirl.create(:menu_category, category: category, menu: menu)
        end
      end
    end
  end

  factory :menu_category do
    association :menu
    association :category
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

  factory :contact_group do
    association :user
    sequence(:name) { |n| "group-#{n}" }
    sequence(:backup_google_group_id) { |n| "backup_google_group_id-#{n}" }
  end

  factory :customer do
    association :user
    association :contact_group
    sequence(:last_name) { |n| "last_name-#{n}" }
    sequence(:first_name) { |n| "first_name-#{n}" }
  end
end

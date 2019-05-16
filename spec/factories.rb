FactoryBot.define do
  factory :shop_menu do
    association :shop
    association :menu
    max_seat_number { 2 }
  end

  factory :user do
    sequence(:email) { |n| "foo#{n}@gmail.com" }
    password { "foobar78" }
    confirmed_at { Time.zone.now }
  end

  factory :shop do
    association :user
    sequence(:name) { |n| "foo#{n}" }
    sequence(:short_name) { |n| "f#{n}" }
    zip_code { "160-0005" }
    phone_number { "123456789" }
    sequence(:email) { |n| "foo#{n}@gmail.com" }
    sequence(:address) { |n| "address#{n}" }
    holiday_working { false }

    trait :holiday_working do
      holiday_working { true }
    end
  end

  factory :reservation_setting_menu do
    association :reservation_setting
    association :menu
  end

  factory :menu_reservation_setting_rule do
    association :menu
    start_date { Time.zone.now.to_date }

    trait :repeating do
      repeats { 2 }

      after(:create) do |rule|
        FactoryBot.create(:shop_menu_repeating_date, shop: menu.shop, menu: menu)
      end
    end
  end

  factory :shop_menu_repeating_date do
    association :shop
    association :menu
    dates { [Time.zone.now.to_date, Time.zone.now.tomorrow.to_date] }
    end_date { dates.last }
  end

  factory :rank do
    association :user
    name { "Regular" }
    key { Rank::REGULAR_KEY }
  end

  factory :category do
    association :user
    sequence(:name) { |n| "category-#{n}" }

    transient do
      menus { [] }
    end

    after(:create) do |category, proxy|
      if proxy.menus.present?
        proxy.menus.each do |menu|
          FactoryBot.create(:menu_category, category: category, menu: menu)
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
    max_customers { 2 }
  end

  factory :contact_group do
    association :user
    sequence(:name) { |n| "group-#{n}" }
    sequence(:backup_google_group_id) { |n| "backup_google_group_id-#{n}" }

    trait :bind_all do
      bind_all { true }
    end
  end
end

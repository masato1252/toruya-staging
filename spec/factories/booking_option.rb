FactoryBot.define do
  factory :booking_option do
    association :user
    name { Faker::Lorem.word }
    minutes { 60 }
    interval { 10 }
    amount { 1000.to_money(:jpy) }
    tax_include { true }
    start_at { Time.zone.local(2016, 8, 22, 8, 0, 0) }
    end_at { Time.zone.local(2016, 8, 22, 19, 0, 0) }

    transient do
      menus { [] }
    end

    trait :single_menu do
      menus { [FactoryBot.create(:menu, :with_reservation_setting, user: user)] }
    end

    trait :single_coperation_menu do
      menus { [FactoryBot.create(:menu, :with_reservation_setting, :coperation, user: user)] }
    end

    trait :multiple_menus do
      menus {
        [
          FactoryBot.create(:menu, :with_reservation_setting, user: user),
          FactoryBot.create(:menu, :with_reservation_setting, user: user)
        ]
      }
    end

    trait :multiple_coperation_menus do
      menus {
        [
          FactoryBot.create(:menu, :with_reservation_setting, user: user),
          FactoryBot.create(:menu, :with_reservation_setting, :coperation, user: user)
        ]
      }
    end

    after(:create) do |option, proxy|
      proxy.menus.each do |menu|
        FactoryBot.create(:booking_option_menu, booking_option: option, menu: menu)
      end
    end
  end
end

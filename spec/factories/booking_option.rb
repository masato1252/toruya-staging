# frozen_string_literal: true

FactoryBot.define do
  factory :booking_option do
    association :user
    name { Faker::Lorem.word }
    minutes { 60 }
    amount { 1000.to_money(:jpy) }
    tax_include { true }
    start_at { Time.new(2016, 6, 8) }
    end_at { nil }
    menu_restrict_order { false }
    option_type { "primary" }

    transient do
      menus { [FactoryBot.create(:menu, :with_reservation_setting, user: user)] }
      booking_pages { [] }
      shops { [] }
      staffs { [] }
    end

    trait :primary do
      option_type { "primary" }
    end

    trait :secondary do
      option_type { "secondary" }
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

    trait :restrict_order do
      menu_restrict_order { true }
    end

    after(:create) do |option, proxy|
      Array.wrap(proxy.menus).each.with_index do |menu, index|
        FactoryBot.create(:booking_option_menu, booking_option: option, menu: menu, priority: index)

        Array.wrap(proxy.shops).each do |shop|
          FactoryBot.create(:shop_menu, menu: menu, shop: shop)
        end

        Array.wrap(proxy.staffs).each.with_index do |staff, priority|
          FactoryBot.create(:staff_menu, menu: menu, staff: staff, priority: priority)
        end
      end

      Array.wrap(proxy.booking_pages).each do |page|
        FactoryBot.create(:booking_page_option, booking_page: page, booking_option: option)
      end

      option.update_columns(minutes: Array.wrap(proxy.menus).sum(&:minutes) )
    end
  end
end

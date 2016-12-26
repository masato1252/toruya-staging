FactoryGirl.define do
  factory :menu do
    transient do
      shop { FactoryGirl.create(:shop, user: user) }
      staffs []
      max_seat_number { 3 }
    end

    transient do
    end

    user { FactoryGirl.create(:user) }
    sequence(:name) { |n| "menu-#{n}" }
    sequence(:short_name) { |n| "m-#{n}" }
    minutes 60
    interval 10
    min_staffs_number 1

    trait :no_manpower do
      min_staffs_number 0
    end

    trait :normal do
      min_staffs_number 1
    end

    trait :lecture do
      min_staffs_number 2
    end

    trait :cooperation do
      min_staffs_number 2
    end

    trait :with_reservation_setting do
      after(:create) do |menu|
        FactoryGirl.create(:reservation_setting, menu: menu, user: menu.user, day_type: "business_days")
      end
    end

    after(:create) do |menu, proxy|
      FactoryGirl.create(:shop_menu, menu: menu, shop: proxy.shop, max_seat_number: proxy.max_seat_number)

      if proxy.staffs.present?
        proxy.staffs.each do |staff|
          FactoryGirl.create(:staff_menu, menu: menu, staff: staff)
        end
      end
    end
  end
end

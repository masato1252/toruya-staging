FactoryGirl.define do
  factory :menu do
    transient do
      shop { FactoryGirl.create(:shop, user: user) }
    end

    user { FactoryGirl.create(:user) }
    sequence(:name) { |n| "menu-#{n}" }
    sequence(:short_name) { |n| "m-#{n}" }
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
end

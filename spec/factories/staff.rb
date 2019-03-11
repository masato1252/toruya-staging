FactoryBot.define do
  factory :staff do
    transient do
      shop { FactoryBot.create(:shop, user: user) }
      menus []
      mapping_user { FactoryBot.create(:user) }
      level { :staff }
    end

    user { FactoryBot.create(:user) }
    sequence(:last_name) { |n| "last_name-#{n}" }
    sequence(:first_name) { |n| "first_name-#{n}" }

    trait :full_time do
      after(:create) do |staff, proxy|
        FactoryBot.create(:business_schedule, shop: proxy.shop, staff: staff, full_time: true)
      end
    end

    trait :manager do
      level :manager
    end

    after(:create) do |staff, proxy|
      FactoryBot.create(:shop_staff, staff: staff, shop: proxy.shop, level: proxy.level)
      FactoryBot.create(:staff_account, staff: staff, owner: proxy.shop.user, user: proxy.mapping_user)
      Array(proxy.menus).each do |menu|
        FactoryBot.create(:staff_menu, menu: menu, staff: staff)
      end
    end
  end
end

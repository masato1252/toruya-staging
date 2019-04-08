FactoryBot.define do
  factory :staff do
    transient do
      shop { FactoryBot.create(:shop, user: user) }
      menus { [] }
      mapping_user { FactoryBot.create(:user) }
      mapping_contact_group { }
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
      level { :manager }
    end

    trait :owner do
      mapping_user { user }
    end

    trait :with_contact_groups do
      mapping_contact_group { FactoryBot.create(:contact_group, user: user) }
    end

    trait :without_staff_account do
      mapping_user { nil }
    end

    after(:create) do |staff, proxy|
      FactoryBot.create(:shop_staff, staff: staff, shop: proxy.shop, level: proxy.level)

      if proxy.mapping_user
        FactoryBot.create(:staff_account, staff: staff, owner: proxy.shop.user, user: proxy.mapping_user)
      end

      Array(proxy.menus).each do |menu|
        FactoryBot.create(:staff_menu, menu: menu, staff: staff)
      end

      if proxy.mapping_contact_group
        FactoryBot.create(:staff_contact_group_relation, staff: staff, contact_group: proxy.mapping_contact_group)
      end
    end
  end
end

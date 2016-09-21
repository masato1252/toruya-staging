FactoryGirl.define do
  factory :staff do
    transient do
      shop { FactoryGirl.create(:shop, user: user) }
    end

    user { FactoryGirl.create(:user) }
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
end

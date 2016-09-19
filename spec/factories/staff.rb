FactoryGirl.define do
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
end

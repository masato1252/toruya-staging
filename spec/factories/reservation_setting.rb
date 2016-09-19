FactoryGirl.define do
  factory :reservation_setting do
    _user = FactoryGirl.create(:user)

    user { _user }

    sequence(:name) { |n| "settings-#{n}" }
    sequence(:short_name) { |n| "s-#{n}" }
    day_type "business_days"

    transient do
      menu FactoryGirl.create(:menu, user: _user)
    end

    trait :weekly do
      day_type "weekly"
      sequence(:days_of_week) { |n| [n%7] }
    end

    trait :number_of_day_monthly do
      day_type "monthly"
      sequence(:day) { |n| n%28 }
    end

    trait :day_of_week_monthly do
      day_type "monthly"
      sequence(:nth_of_week) { |n| n%4 }
      sequence(:days_of_week) { |n| [n%7] }
    end

    after(:create) do |setting, proxy|
      FactoryGirl.create(:reservation_setting_menu, reservation_setting: setting, menu: proxy.menu)
      FactoryGirl.create(:menu_reservation_setting_rule, menu: proxy.menu)
    end
  end
end

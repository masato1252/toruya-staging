FactoryBot.define do
  factory :custom_schedule do
    association :user
    association :shop
    association :staff
    open false

    trait :opened do
      open true
      user nil
    end

    trait :closed do
      open false
    end

    trait :for_shop do
      staff nil
      user nil
    end

    trait :personal do
      shop nil
      staff nil
    end
  end
end

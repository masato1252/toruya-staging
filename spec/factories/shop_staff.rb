FactoryBot.define do
  factory :shop_staff do
    association :shop
    association :staff
    level { :staff }

    trait :staff do
      level { :staff }
    end

    trait :manager do
      level { :manager }
    end
  end
end

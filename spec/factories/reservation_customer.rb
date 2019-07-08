FactoryBot.define do
  factory :reservation_customer do
    association :reservation
    association :customer
    state { :pending }

    trait :pending do
      state { :pending }
    end

    trait :accepted do
      state { :accepted }
    end

    trait :canceled do
      state { :canceled }
    end
  end
end

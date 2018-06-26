FactoryBot.define do
  factory :subscription do
    association :user
    plan { Plan.free_level.take }
    stripe_customer_id { SecureRandom.hex }
    recurring_day { Subscription.today.day }
    expired_date { Subscription.today.tomorrow }

    trait :free do
      plan { Plan.free_level.take }
    end

    trait :basic do
      plan { Plan.basic_level.take }
    end

    trait :premium do
      plan { Plan.premium_level.take }
    end
  end
end

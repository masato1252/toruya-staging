FactoryBot.define do
  factory :subscription_charge do
    association :user
    plan { Plan.second } # basic plan
    amount { plan.cost.is_a?(Array) ? plan.cost.first : plan.cost }
    charge_date { Subscription.today }

    trait :manual do
      manual { true }
    end

    trait :completed do
      state { SubscriptionCharge.states[:completed] }
    end

    trait :refunded do
      state { SubscriptionCharge.states[:refunded] }
    end
  end
end

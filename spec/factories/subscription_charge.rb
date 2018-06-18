FactoryBot.define do
  factory :subscription_charge do
    association :user
    plan { Plan.second } # basic plan
    amount { plan.cost }
    charge_date { Subscription.today }

    trait :completed do
      state SubscriptionCharge.states[:completed]
    end
  end
end

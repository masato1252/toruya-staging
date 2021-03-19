# frozen_string_literal: true

FactoryBot.define do
  factory :subscription_charge do
    association :user
    plan { Plan.second } # basic plan
    amount { plan.cost.is_a?(Array) ? plan.cost.first : plan.cost }
    charge_date { Subscription.today }
    expired_date { Subscription.today.advance(months: 1) }

    trait :manual do
      manual { true }
    end

    trait :completed do
      state { SubscriptionCharge.states[:completed] }
    end

    trait :refunded do
      state { SubscriptionCharge.states[:refunded] }
    end

    trait :plan_subscruption do
      after(:create) do |charge, _|
        charge.details = { type: SubscriptionCharge::TYPES[:plan_subscruption] }
        charge.save!
      end
    end
  end
end

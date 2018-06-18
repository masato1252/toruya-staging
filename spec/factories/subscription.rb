FactoryBot.define do
  factory :subscription do
    association :user
    plan { Plan.first } # free plan
    stripe_customer_id { SecureRandom.hex }
    recurring_day { Subscription.today.day }
    expired_date { Subscription.today }
  end
end

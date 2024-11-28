FactoryBot.define do
  factory :customer_ticket do
    association :customer
    association :ticket
    total_quota { 3 }
    consumed_quota { 0 }
    state { "active" }
    expire_at { 1.day.from_now }
    code { SecureRandom.uuid }
  end
end
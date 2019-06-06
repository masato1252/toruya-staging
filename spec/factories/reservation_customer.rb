FactoryBot.define do
  factory :reservation_customer do
    association :reservation
    association :customer
  end
end

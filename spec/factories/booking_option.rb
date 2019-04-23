FactoryBot.define do
  factory :booking_option do
    association :user
    name { Faker::Lorem.word }
    minutes { 60 }
    interval { 10 }
    amount { 1000.to_money(:jpy) }
    tax_include { true }
    start_at { Time.zone.local(2016, 8, 22, 8, 0, 0) }
    end_at { Time.zone.local(2016, 8, 22, 19, 0, 0) }
  end
end

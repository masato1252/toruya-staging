FactoryBot.define do
  factory :booking_page do
    association :user
    shop { FactoryBot.create(:shop, user: user) }
    name { Faker::Lorem.word }
    title { Faker::Lorem.word }
    greeting { Faker::Lorem.word }
    note { Faker::Lorem.word }
    interval { 10 }
    start_at { Time.zone.local(2016, 8, 22, 8, 0, 0) }
    end_at { Time.zone.local(2016, 8, 22, 19, 0, 0) }
    overbooking_restriction { true }
  end
end

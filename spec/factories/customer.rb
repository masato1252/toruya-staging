FactoryBot.define do
  factory :customer do
    association :user
    contact_group { FactoryBot.create(:contact_group, user: user) }
    last_name { Faker::Lorem.word }
    first_name { Faker::Lorem.word }
  end
end

FactoryGirl.define do
  factory :reservation do
    association :shop
    association :menu
    start_time { Time.zone.now }
    end_time { Time.zone.now.advance(hours: 1) }
    staff_ids { FactoryGirl.create(:staff).id }
    customer_ids { [FactoryGirl.create(:customer).id] }

    trait :pending do
      aasm_state "pending"
    end

    trait :reserved do
      aasm_state "reserved"
    end
  end
end

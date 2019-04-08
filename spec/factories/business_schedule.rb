FactoryBot.define do
  factory :business_schedule do
    association :shop
    day_of_week { start_time.wday }
    business_state { "opened" }
    start_time { Time.zone.local(2016, 8, 22, 8, 0, 0) }
    end_time { Time.zone.local(2016, 8, 22, 19, 0, 0) }

    trait :full_time do
      full_time { true }
    end

    trait :opened do
      business_state { "opened" }
    end
  end
end

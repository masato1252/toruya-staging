FactoryBot.define do
  factory :business_schedule do
    association :shop
    day_of_week { start_time.wday }
    business_state { "opened" }
    # Monday
    start_time { Time.zone.local(2016, 8, 22, 9, 0, 0) }
    end_time { Time.zone.local(2016, 8, 22, 17, 0, 0) }

    trait :full_time do
      full_time { true }
    end

    trait :opened do
      business_state { "opened" }
    end
  end
end

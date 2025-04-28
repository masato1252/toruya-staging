FactoryBot.define do
  factory :survey_activity_slot do
    start_time { 1.day.from_now }
    end_time { 1.day.from_now + 2.hours }
    association :survey_activity
  end
end
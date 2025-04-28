FactoryBot.define do
  factory :survey_activity do
    name { "Test Activity" }
    max_participants { 10 }
    price_cents { 1000 }
    currency { "JPY" }
    association :survey_question
    position { 1 }
  end
end
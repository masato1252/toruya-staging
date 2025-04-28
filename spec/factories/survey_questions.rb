FactoryBot.define do
  factory :survey_question do
    description { "Test Question" }
    question_type { "text" }
    required { false }
    position { 1 }
    association :survey

    trait :activity do
      question_type { "activity" }
    end

    trait :single_selection do
      question_type { "single_selection" }
    end

    trait :multiple_selection do
      question_type { "multiple_selection" }
    end
  end
end
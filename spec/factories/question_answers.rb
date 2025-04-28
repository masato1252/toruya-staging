FactoryBot.define do
  factory :question_answer do
    association :survey_response
    association :survey_question
    survey_question_snapshot { "Test Question" }

    trait :with_text do
      text_answer { "Test Answer" }
    end

    trait :with_option do
      association :survey_option
      survey_option_snapshot { "Test Option" }
    end

    trait :with_activity do
      association :survey_activity
      survey_activity_snapshot { "Test Activity" }
    end
  end
end
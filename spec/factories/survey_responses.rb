FactoryBot.define do
  factory :survey_response do
    association :survey
    association :owner, factory: :customer
    uuid { SecureRandom.uuid }
  end
end
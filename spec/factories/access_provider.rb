FactoryBot.define do
  factory :access_provider do
    association :user
    access_token { SecureRandom.uuid }
    refresh_token { SecureRandom.uuid }
  end
end

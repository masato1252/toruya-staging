FactoryBot.define do
  factory :survey do
    title { "Test Survey" }
    description { "Test Survey Description" }
    active { true }
    association :user
    association :owner, factory: :shop
    slug { SecureRandom.uuid }
  end
end
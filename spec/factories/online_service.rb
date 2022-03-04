# frozen_string_literal: true

FactoryBot.define do
  factory :online_service do
    association :user
    name { Faker::Lorem.word }
    goal_type { "collection" }
    solution_type { "video" }
    company { FactoryBot.create(:profile, user: user) }
    slug { SecureRandom.hex  }

    trait :external do
      goal_type { "external" }
      solution_type { "external" }
    end

    trait :membership do
      goal_type { "membership" }
      solution_type { "membership" }
      stripe_product_id do
        Stripe::Product.create(
          { name: name },
          stripe_account: user.stripe_provider.uid
        ).id
      end
    end
  end
end

# frozen_string_literal: true

FactoryBot.define do
  factory :sale_page do
    association :user
    staff { FactoryBot.create(:staff, user: user) }
    sale_template { FactoryBot.create(:sale_template) }

    trait :online_service do
      product { FactoryBot.create(:online_service, user: user) }
    end

    trait :booking_page do
      product { FactoryBot.create(:booking_page, user: user) }
    end

    trait :paid_version do
      selling_price_amount_cents { 1_000 }
    end
  end
end

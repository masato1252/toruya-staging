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

    trait :one_time_payment do
      selling_price_amount_cents { 1_000 }
    end

    trait :multiple_times_payment do
      selling_multiple_times_price { [1000, 1000] }
    end

    trait :recurring_payment do
      recurring_prices do
        [
          RecurringPrice.new(
            interval: 'month',
            amount: 1000,
            stripe_price_id: "price_123",
            active: true
          ).attributes,
          RecurringPrice.new(
            interval: 'year',
            amount: 10_000,
            stripe_price_id: "price_456",
            active: true
          ).attributes
        ]
      end
    end
  end
end

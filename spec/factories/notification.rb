# frozen_string_literal: true

FactoryBot.define do
  factory :notification do
    association :user
    phone_number { Faker::PhoneNumber.phone_number }
    content { Faker::Lorem.sentence }
    customer_id { nil }
    reservation_id { nil }
    charged { false }
  end
end
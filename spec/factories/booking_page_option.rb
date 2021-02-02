# frozen_string_literal: true

FactoryBot.define do
  factory :booking_page_option do
    association :booking_page
    association :booking_option
  end
end

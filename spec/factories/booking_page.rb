# frozen_string_literal: true

FactoryBot.define do
  factory :booking_page do
    association :user
    shop { FactoryBot.create(:shop, user: user) }
    name { "foo" }
    title { "foo" }
    greeting { "foo" }
    note { "foo" }
    interval { 10 }
    start_at { Time.zone.local(2016, 8, 22, 8, 0, 0) }
    end_at { Time.zone.local(2016, 8, 22, 19, 0, 0) }
    overbooking_restriction { true }
    slug { SecureRandom.alphanumeric(10) }

    trait :rich_menu_only do
      rich_menu_only { true }
    end

    before(:create) do |booking_page, evaluator|
      if booking_page.start_at
        booking_page.start_at_date_part = booking_page.start_at.to_fs(:date)
        booking_page.start_at_time_part = booking_page.start_at.to_fs(:time)
      end

      if booking_page.end_at
        booking_page.end_at_date_part = booking_page.end_at.to_fs(:date)
        booking_page.end_at_time_part = booking_page.end_at.to_fs(:time)
      end
    end
  end
end

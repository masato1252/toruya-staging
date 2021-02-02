# frozen_string_literal: true

FactoryBot.define do
  factory :booking_page_special_date do
    association :booking_page
    start_at { Time.zone.local(2016, 8, 22, 8, 0, 0) }
    end_at { Time.zone.local(2016, 8, 22, 19, 0, 0) }

    before(:create) do |special_date, evaluator|
      if special_date.start_at
        special_date.start_at_date_part = special_date.start_at.to_s(:date)
        special_date.start_at_time_part = special_date.start_at.to_s(:time)
      end

      if special_date.end_at
        special_date.end_at_date_part = special_date.end_at.to_s(:date)
        special_date.end_at_time_part = special_date.end_at.to_s(:time)
      end
    end
  end
end

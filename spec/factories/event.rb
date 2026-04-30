# frozen_string_literal: true

FactoryBot.define do
  factory :event do
    association :user
    sequence(:title) { |n| "event-#{n}" }
    sequence(:slug)  { |n| "event-#{n}" }
    published { true }
    start_at { 1.day.from_now }
    end_at { 7.days.from_now }
    stamp_rally_phases { [] }

    trait :pre_event do
      start_at { 1.day.from_now }
      end_at { 7.days.from_now }
    end

    trait :during_event do
      start_at { 1.day.ago }
      end_at { 7.days.from_now }
    end

    trait :ended do
      start_at { 14.days.ago }
      end_at { 7.days.ago }
    end
  end

  factory :event_content do
    association :event
    sequence(:title) { |n| "content-#{n}" }
    content_type { :seminar }
    status { :published }

    trait :unpublished do
      status { :unpublished }
    end

    trait :published do
      status { :published }
    end
  end

  factory :event_line_user do
    sequence(:line_user_id) { |n| "U#{format('%015d', n)}" }
    sequence(:display_name) { |n| "line-user-#{n}" }
  end
end

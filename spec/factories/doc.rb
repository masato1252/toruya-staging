# frozen_string_literal: true

FactoryBot.define do
  factory :doc do
    sequence(:title) { |n| "doc-#{n}" }
    document_url { "https://example.com/material.pdf" }
    status { :published }

    trait :unpublished do
      status { :unpublished }
    end
  end

  factory :doc_line_user do
    sequence(:line_user_id) { |n| "U#{format('%015d', n)}" }
    sequence(:display_name) { |n| "doc-line-user-#{n}" }
  end

  factory :doc_download do
    association :doc
    association :doc_line_user
    first_visited_at { Time.current }
    download_count { 0 }
  end
end

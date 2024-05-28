# frozen_string_literal: true

FactoryBot.define do
  factory :ticket do
    association :user
    ticket_type { 'single' }
  end
end

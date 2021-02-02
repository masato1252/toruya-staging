# frozen_string_literal: true

FactoryBot.define do
  factory :staff_contact_group_relation do
    association :staff
    association :contact_group
  end
end

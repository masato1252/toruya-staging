# frozen_string_literal: true

FactoryBot.define do
  factory :staff_account do
    phone_number { Faker::PhoneNumber.phone_number }
    user { FactoryBot.create(:user) }
    owner { FactoryBot.create(:user) }
    staff { FactoryBot.create(:staff) }
    state { StaffAccount.states[:active] }
    level { user == owner ? :owner : :employee }
    token { SecureRandom.hex }
    active_uniqueness { true }

    trait :employee do
      level { :employee }
    end

    trait :pending do
      state { :pending }
      active_uniqueness { nil }
    end

    trait :phone_number do
      phone_number { Faker::PhoneNumber.phone_number }
    end

    trait :email do
      email { Faker::Internet.email }
    end
  end
end

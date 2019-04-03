FactoryBot.define do
  factory :staff_account do
    email { Faker::Internet.email }
    user { FactoryBot.create(:user) }
    owner { FactoryBot.create(:user) }
    staff { FactoryBot.create(:staff) }
    state { StaffAccount.states[:active] }
    level { user == owner ? :owner : :employee }
    token { SecureRandom.hex }
    active_uniqueness { true }

    trait :employee do
      level :employee
    end

    trait :pending do
      state :pending
      active_uniqueness nil
    end
  end
end

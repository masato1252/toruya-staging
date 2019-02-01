FactoryBot.define do
  factory :staff_account do
    sequence(:email) { |n| "foo#{n}@gmail.com" }
    user { FactoryBot.create(:user) }
    owner { FactoryBot.create(:user) }
    staff { FactoryBot.create(:staff) }
    state { StaffAccount.states[:active] }
    level { :staff }

    trait :manager do
      level :manager
    end
  end
end

FactoryBot.define do
  factory :referral do
    association :referrer
    association :user
    state { :active }
  end
end

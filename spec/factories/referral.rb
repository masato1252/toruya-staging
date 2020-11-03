FactoryBot.define do
  factory :referral do
    referrer { FactoryBot.create(:user) }
    referee { FactoryBot.create(:user) }
    state { :active }
  end
end

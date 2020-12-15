FactoryBot.define do
  factory :social_rich_menu do
    association :social_account
    social_rich_menu_id { SecureRandom.hex }
    social_name { Faker::Lorem.word }

    trait :reservations do
      social_name { SocialAccounts::RichMenus::CustomerReservations::KEY }
    end
  end
end

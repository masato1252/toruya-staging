# frozen_string_literal: true

FactoryBot.define do
  factory :social_rich_menu do
    association :social_account
    social_rich_menu_id { SecureRandom.hex }
    social_name { Faker::Lorem.word }

    trait :reservations do
      social_name { SocialAccounts::RichMenus::CustomerReservations::KEY }
    end

    trait :user_guest do
      social_account { nil }
      social_name { UserBotLines::RichMenus::Guest::KEY }
    end

    trait :user_dashboard do
      social_account { nil }
      social_name { UserBotLines::RichMenus::Dashboard::KEY }
    end

    trait :user_dashboard_with_notifications do
      social_account { nil }
      social_name { UserBotLines::RichMenus::DashboardWithNotifications::KEY }
    end

    trait :user_booking do
      social_account { nil }
      social_name { UserBotLines::RichMenus::Booking::KEY }
    end
  end
end

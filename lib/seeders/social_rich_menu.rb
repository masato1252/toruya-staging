module Seeders
  class SocialRichMenu
    def self.seed!
      FactoryBot.create(:social_rich_menu, :user_guest)
      FactoryBot.create(:social_rich_menu, :user_dashboard)
      FactoryBot.create(:social_rich_menu, :user_dashboard_with_notifications)
      FactoryBot.create(:social_rich_menu, :user_booking)
    end
  end
end

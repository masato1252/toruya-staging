# frozen_string_literal: true

require "liff_routing"

module UserBotLines
  module RichMenus
    class PromotionsFromNotificationDashboard < ActiveInteraction::Base
      KEY = "user_promotions_from_notification_dashboard".freeze

      # 2500x1686
      # | 1 | 2 |
      # | 3 | 4 |
      def execute
        body = {
          "size": {
            "width": 2500,
            "height": 1686
          },
          "selected": true,
          "name": KEY,
          "chatBarText": I18n.t("user_bot.guest.rich_menu_bar"),
          "areas": [
            {
              # 1
              "bounds": {
                "x": 0,
                "y": 0,
                "width": 1250,
                "height": 843
              },
              "action": LineActions::Postback.template(
                action: UserBotLines::Actions::SwitchRichMenu.class_name,
                enabled: true,
                params: { rich_menu_key: UserBotLines::RichMenus::DashboardWithNotifications::KEY },
                displayText: false
              )
            },
            {
              # 2
              "bounds": {
                "x": 1250,
                "y": 0,
                "width": 1250,
                "height": 843
              },
              "action": LineActions::Postback.template(
                action: UserBotLines::Actions::SwitchRichMenu.class_name,
                enabled: true,
                params: { rich_menu_key: UserBotLines::RichMenus::SalesFromNotificationDashboard::KEY },
                displayText: false
              )
            },
            {
              # 4
              "bounds": {
                "x": 1250,
                "y": 843,
                "width": 1250,
                "height": 843
              },
              "action": LineActions::Postback.template(
                action: UserBotLines::Actions::SwitchRichMenu.class_name,
                enabled: true,
                params: { rich_menu_key: UserBotLines::RichMenus::LineMarketingFromNotificationDashboard::KEY },
                displayText: false
              )
            },
          ]
        }

        compose(
          ::RichMenus::ToruyaOfficialCreate,
          body: body,
          key: KEY,
          internal_name: KEY,
          bar_label: I18n.t("user_bot.guest.rich_menu_bar")
        )
      end
    end
  end
end

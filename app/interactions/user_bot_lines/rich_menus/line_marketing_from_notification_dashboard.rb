# frozen_string_literal: true

require "liff_routing"

module UserBotLines
  module RichMenus
    class LineMarketingFromNotificationDashboard < ActiveInteraction::Base
      KEY = "user_line_marketing_from_notification_dashboard".freeze

      # 2500x1686
      # | 1 | 2 | 3 |
      string :locale

      def execute
        body = {
          "size": {
            "width": 2500,
            "height": 843
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
                "width": 833,
                "height": 843
              },
              "action": LineActions::Postback.template(
                action: UserBotLines::Actions::SwitchRichMenu.class_name,
                enabled: true,
                params: { rich_menu_key: UserBotLines::RichMenus::PromotionsFromNotificationDashboard::KEY },
                displayText: false
              )
            },
            {
              # 2
              "bounds": {
                "x": 834,
                "y": 0,
                "width": 833,
                "height": 843
              },
              "action": LineActions::Uri.template(
                label: I18n.t("toruya_line.actions.label.broadcasts"),
                url: LiffRouting.liff_url(:new_broadcast)
              )
            },
            {
              # 3
              "bounds": {
                "x": 1667,
                "y": 0,
                "width": 833,
                "height": 843
              },
              "action": LineActions::Uri.template(
                label: I18n.t("toruya_line.actions.label.broadcasts"),
                url: LiffRouting.liff_url(:broadcasts)
              )
            },
          ]
        }

        compose(
          ::RichMenus::ToruyaOfficialCreate,
          body: body,
          key: KEY,
          internal_name: KEY,
          bar_label: I18n.t("user_bot.guest.rich_menu_bar"),
          locale: locale
        )
      end
    end
  end
end

require "liff_routing"

module UserBotLines
  module RichMenus
    class Dashboard < ActiveInteraction::Base
      KEY = "user_dashboard".freeze

      # 2500x1686
      # | 1 | 2 | 3 |
      # | 4 | 5 | 6 |
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
                "width": 833,
                "height": 843
              },
              "action": LineActions::Uri.template(
                label: I18n.t("toruya_line.actions.label.reservations"),
                url: LiffRouting.liff_url(:schedules)
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
                  label: I18n.t("toruya_line.actions.label.customers"),
                url: LiffRouting.liff_url(:customers)
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
                label: I18n.t("toruya_line.actions.label.settings"),
                url: LiffRouting.liff_url(:settings)
              )
            },
            {
              # 4
              "bounds": {
                "x": 0,
                "y": 843,
                "width": 833,
                "height": 843
              },
              "action": LineActions::Postback.template(
                action: UserBotLines::Actions::SwitchRichMenu.class_name,
                enabled: true,
                params: { rich_menu_key: UserBotLines::RichMenus::Booking::KEY },
                displayText: false
              )
            }
          ]
        }

        compose(
          ::RichMenus::Create,
          body: body,
          key: KEY
        )
      end
    end
  end
end

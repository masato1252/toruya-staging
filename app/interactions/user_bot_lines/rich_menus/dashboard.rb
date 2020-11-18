require "liff_routing"

module UserBotLines
  module RichMenus
    class Dashboard < ActiveInteraction::Base
      KEY = "user_dashboard".freeze

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

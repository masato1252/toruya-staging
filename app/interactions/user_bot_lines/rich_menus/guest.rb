require "liff_routing"

module UserBotLines
  module RichMenus
    class Guest < ActiveInteraction::Base
      KEY = "user_guest".freeze

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
                "width": 1250,
                "height": 843
              },
              "action": LineActions::Uri.template(
                label: I18n.t("toruya_line.actions.label.sign_in"),
                url: LiffRouting.liff_url(:users_connect)
              )
            },
            {
              "bounds": {
                "x": 1251,
                "y": 0,
                "width": 1250,
                "height": 843
              },
              "action": LineActions::Uri.template(
                label: I18n.t("toruya_line.actions.label.signup"),
                url: LiffRouting.liff_url(:users_sign_up)
              )
            }
          ]
        }

        compose(
          ::RichMenus::Create,
          body: body,
          key: KEY,
          default_menu: true
        )
      end
    end
  end
end

require "liff_routing"

module UserBotLines
  module RichMenus
    class Sales < ActiveInteraction::Base
      KEY = "user_sales".freeze

      # 2500x1686
      # | 1 | 2 | 3 |
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
                params: { rich_menu_key: UserBotLines::RichMenus::Promotions::KEY },
                displayText: false
              )
            },
            {
              # 2
              "bounds": {
                "x": 844,
                "y": 0,
                "width": 833,
                "height": 843
              },
              "action": LineActions::Uri.template(
                label: I18n.t("toruya_line.actions.label.sales"),
                url: LiffRouting.liff_url(:new_sales)
              )
            },
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

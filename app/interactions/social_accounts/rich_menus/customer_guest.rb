module SocialAccounts
  module RichMenus
    class CustomerGuest < ActiveInteraction::Base
      KEY = "customer_guest".freeze

      object :social_account

      def execute
        identify_shop_customer_sentence = I18n.t("line.actions.label.#{Lines::Menus::Guest::IDENTIFY_SHOP_CUSTOMER}")
        body = {
          "size": {
            "width": 2500,
            "height": 843
          },
          "selected": true,
          "name": KEY,
          "chatBarText": identify_shop_customer_sentence,
          "areas": [
            {
              "bounds": {
                "x": 0,
                "y": 0,
                "width": 2500,
                "height": 843
              },
              "action": {
                "type": "message",
                "label": identify_shop_customer_sentence,
                "text": identify_shop_customer_sentence
              }
            }
          ]
        }

        compose(
          ::RichMenus::Create,
          social_account: social_account,
          body: body,
          key: KEY,
          default_menu: true
        )
      end
    end
  end
end

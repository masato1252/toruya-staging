module SocialAccounts
  module RichMenus
    class CustomerReservations < ActiveInteraction::Base
      KEY = "customer_reservations".freeze

      object :social_account

      def execute
        sentence = I18n.t("line.bot.features.online_booking.rich_menu.bar_text")
        body = {
          "size": {
            "width": 2500,
            "height": 843
          },
          "selected": true,
          "name": KEY,
          "chatBarText": sentence,
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
                "label": sentence,
                "text": sentence
              }
            }
          ]
        }

        compose(
          ::RichMenus::Create,
          social_account: social_account,
          body: body,
          key: KEY
        )
      end
    end
  end
end

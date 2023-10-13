# frozen_string_literal: true

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
                "width": 833,
                "height": 843
              },
              "action": {
                "type": "message",
                "label": I18n.t("line.bot.keywords.incoming_reservations"),
                "text": I18n.t("line.bot.keywords.incoming_reservations")
              }
            },
            {
              "bounds": {
                "x": 834,
                "y": 0,
                "width": 833,
                "height": 843
              },
              "action": {
                "type": "message",
                "label": I18n.t("line.bot.keywords.booking_pages"),
                "text": I18n.t("line.bot.keywords.booking_pages")
              }
            },
            {
              "bounds": {
                "x": 1667,
                "y": 0,
                "width": 833,
                "height": 843
              },
              "action": {
                "type": "message",
                "label": I18n.t("line.bot.keywords.contacts"),
                "text": I18n.t("line.bot.keywords.contacts")
              }
            }
          ]
        }

        compose(
          ::RichMenus::Create,
          social_account: social_account,
          body: body,
          key: KEY,
          default_menu: true,
          current: true
        )
      end
    end
  end
end

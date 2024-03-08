# frozen_string_literal: true

require "liff_routing"

module UserBotLines
  module RichMenus
    class BookingFromNotificationDashboard < ActiveInteraction::Base
      KEY = "user_booking_from_notification_dashboard".freeze

      # 2500x1686
      # |  1  |  2  |
      # | 3 | 4 | 5 |
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
              "action": LineActions::Uri.template(
                label: I18n.t("toruya_line.actions.label.booking"),
                url: LiffRouting.liff_url(:new_booking_setting)
              )
            },
            {
              # 3
              "bounds": {
                "x": 0,
                "y": 843,
                "width": 833,
                "height": 843
              },
              "action": LineActions::Uri.template(
                label: I18n.t("toruya_line.actions.label.menus"),
                url: LiffRouting.liff_url(:menus)
              )
            },
            {
              # 4
              "bounds": {
                "x": 834,
                "y": 843,
                "width": 833,
                "height": 843
              },
              "action": LineActions::Uri.template(
                label: I18n.t("toruya_line.actions.label.booking"),
                url: LiffRouting.liff_url(:booking_options)
              )
            },
            {
              # 5
              "bounds": {
                "x": 1667,
                "y": 843,
                "width": 833,
                "height": 843
              },
              "action": LineActions::Uri.template(
                label: I18n.t("toruya_line.actions.label.booking"),
                url: LiffRouting.liff_url(:booking_pages)
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

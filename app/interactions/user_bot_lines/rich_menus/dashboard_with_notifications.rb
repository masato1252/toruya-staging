# frozen_string_literal: true

require "liff_routing"

module UserBotLines
  module RichMenus
    class DashboardWithNotifications < ActiveInteraction::Base
      KEY = "user_dashboard_with_notifications".freeze

      string :locale

      # 2500x1686
      # JP
      # |     7     |
      # | 1 | 2 | 3 |
      # | 4 | 5 | 6 |
      # TW
      # |     7     |
      # |  1  |  2  |
      # | 3 | 4 | 5 |
      def execute
        I18n.with_locale(locale) do
          compose(
            ::RichMenus::ToruyaOfficialCreate,
            body: locale == "tw" ? tw_body : ja_body,
            key: KEY,
            internal_name: KEY,
            bar_label: I18n.t("user_bot.guest.rich_menu_bar"),
            locale: locale
          )
        end
      end

      private

      def tw_body
        {
          "size": {
            "width": 2500,
            "height": 1686
          },
          "selected": true,
          "name": KEY,
          "chatBarText": I18n.t("user_bot.guest.rich_menu_bar"),
          "areas": [
            {
              # 7
              "bounds": {
                "x": 0,
                "y": 0,
                "width": 2500,
                "height": 230,
              },
              "action": LineActions::Uri.template(
                label: I18n.t("toruya_line.actions.label.notifications"),
                url: LiffRouting.liff_url(:notifications, locale)
              )
            },
            {
              # 1
              "bounds": {
                "x": 0,
                "y": 230,
                "width": 833,
                "height": 728
              },
              "action": LineActions::Uri.template(
                label: I18n.t("toruya_line.actions.label.reservations"),
                url: LiffRouting.liff_url(:schedules, locale)
              )
            },
            {
              # 2
              "bounds": {
                "x": 1250,
                "y": 230,
                "width": 1250,
                "height": 728
              },
              "action": LineActions::Uri.template(
                label: I18n.t("toruya_line.actions.label.customers"),
                url: LiffRouting.liff_url(:customers, locale)
              )
            },
            {
              # 3
              "bounds": {
                "x": 0,
                "y": 843,
                "width": 833,
                "height": 728
              },
              "action": LineActions::Uri.template(
                label: I18n.t("toruya_line.actions.label.booking_pages"),
                url: LiffRouting.liff_url(:booking_pages, locale)
              )
            },
            {
              # 4
              "bounds": {
                "x": 834,
                "y": 843,
                "width": 833,
                "height": 728
              },
              "action": LineActions::Uri.template(
                label: I18n.t("toruya_line.actions.label.broadcasts"),
                url: LiffRouting.liff_url(:broadcasts, locale)
              )
            },
            {
              # 5
              "bounds": {
                "x": 1667,
                "y": 843,
                "width": 833,
                "height": 728
              },
              "action": LineActions::Uri.template(
                label: I18n.t("toruya_line.actions.label.settings"),
                url: LiffRouting.liff_url(:settings, locale)
              )
            }
          ]
        }
      end

      def ja_body
        {
          "size": {
            "width": 2500,
            "height": 1686
          },
          "selected": true,
          "name": KEY,
          "chatBarText": I18n.t("user_bot.guest.rich_menu_bar"),
          "areas": [
            {
              # 7
              "bounds": {
                "x": 0,
                "y": 0,
                "width": 2500,
                "height": 230,
              },
              "action": LineActions::Uri.template(
                label: I18n.t("toruya_line.actions.label.notifications"),
                url: LiffRouting.liff_url(:notifications, locale)
              )
            },
            {
              # 1
              "bounds": {
                "x": 0,
                "y": 230,
                "width": 833,
                "height": 728
              },
              "action": LineActions::Uri.template(
                label: I18n.t("toruya_line.actions.label.reservations"),
                url: LiffRouting.liff_url(:schedules, locale)
              )
            },
            {
              # 2
              "bounds": {
                "x": 834,
                "y": 230,
                "width": 833,
                "height": 728
              },
              "action": LineActions::Uri.template(
                label: I18n.t("toruya_line.actions.label.customers"),
                url: LiffRouting.liff_url(:customers, locale)
              )
            },
            {
              # 3
              "bounds": {
                "x": 1667,
                "y": 230,
                "width": 833,
                "height": 728
              },
              "action": LineActions::Uri.template(
                label: I18n.t("toruya_line.actions.label.settings"),
                url: LiffRouting.liff_url(:settings, locale)
              )
            },
            {
              # 4
              "bounds": {
                "x": 0,
                "y": 843,
                "width": 833,
                "height": 728
              },
              "action": LineActions::Postback.template(
                action: UserBotLines::Actions::SwitchRichMenu.class_name,
                enabled: true,
                params: { rich_menu_key: UserBotLines::RichMenus::BookingFromNotificationDashboard::KEY },
                displayText: false
              )
            },
            {
              # 5
              "bounds": {
                "x": 834,
                "y": 843,
                "width": 833,
                "height": 728
              },
              "action": LineActions::Postback.template(
                action: UserBotLines::Actions::SwitchRichMenu.class_name,
                enabled: true,
                params: { rich_menu_key: UserBotLines::RichMenus::OnlineServiceFromNotificationDashboard::KEY },
                displayText: false
              )
            },
            {
              # 6
              "bounds": {
                "x": 1667,
                "y": 843,
                "width": 833,
                "height": 728
              },
              "action": LineActions::Postback.template(
                action: UserBotLines::Actions::SwitchRichMenu.class_name,
                enabled: true,
                params: { rich_menu_key: UserBotLines::RichMenus::PromotionsFromNotificationDashboard::KEY },
                displayText: false
              )
            }
          ]
        }
      end
    end
  end
end
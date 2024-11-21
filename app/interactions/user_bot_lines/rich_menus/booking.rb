# frozen_string_literal: true

require "liff_routing"

module UserBotLines
  module RichMenus
    class Booking < ActiveInteraction::Base
      KEY = "user_booking".freeze

      string :locale

      # 2500x1686
      # |  1  |  2  |
      # | 3 | 4 | 5 |
      def execute
        I18n.with_locale(locale) do
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
                  params: { rich_menu_key: UserBotLines::RichMenus::Dashboard::KEY },
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
                  url: LiffRouting.liff_url(:new_booking_setting, locale)
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
                  url: LiffRouting.liff_url(:menus, locale)
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
                  url: LiffRouting.liff_url(:booking_options, locale)
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
                  url: LiffRouting.liff_url(:booking_pages, locale)
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
end

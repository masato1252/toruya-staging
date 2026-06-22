# frozen_string_literal: true

require "liff_routing"
require "line_client"
require "timeout"

module UserBotLines
  module RichMenus
    module Expo2026Campaign
      END_ON = Date.new(2026, 8, 30)
      LOCALE = "ja"
      EVENT_SLUG = "expo2026"
      LINK_TIMEOUT_SECONDS = 10
      NOLOGIN_KEYS = (1..4).map { |index| "expo2026_nologin_%02d" % index }.freeze
      ONLY_EVENT_KEY = "expo2026_onlyevent".freeze

      module_function

      def active?
        Date.current <= END_ON
      end

      def nologin_key_for(social_user)
        NOLOGIN_KEYS[social_user.id % NOLOGIN_KEYS.size]
      end

      def link_nologin_menu(social_user)
        return unless active?
        return unless social_user&.user_id.nil?
        return unless social_user.locale == LOCALE

        rich_menu = SocialRichMenu.find_by(social_name: nologin_key_for(social_user), locale: LOCALE)
        return unless rich_menu

        Timeout.timeout(LINK_TIMEOUT_SECONDS) do
          ::RichMenus::Connect.run(social_target: social_user, social_rich_menu: rich_menu)
        end
      rescue Timeout::Error => e
        Rails.logger.warn("[Expo2026Campaign] Timed out linking nologin rich menu: social_user_id=#{social_user&.id} error=#{e.message}")
      rescue StandardError => e
        Rails.logger.warn("[Expo2026Campaign] Failed to link nologin rich menu: social_user_id=#{social_user&.id} error=#{e.class}: #{e.message}")
      end

      def link_only_event_menu(event_line_user)
        return unless active?
        return unless event_line_user
        return if event_line_user.toruya_registered?

        rich_menu = SocialRichMenu.find_by(social_name: ONLY_EVENT_KEY, locale: LOCALE)
        return unless rich_menu

        response = Timeout.timeout(LINK_TIMEOUT_SECONDS) do
          UserBotSocialAccount.client.link_user_rich_menu(event_line_user.line_user_id, rich_menu.social_rich_menu_id)
        end
        Rails.logger.warn("[Expo2026Campaign] Failed to link only event rich menu: event_line_user_id=#{event_line_user.id}") unless response.is_a?(Net::HTTPOK)
      rescue Timeout::Error => e
        Rails.logger.warn("[Expo2026Campaign] Timed out linking only event rich menu: event_line_user_id=#{event_line_user&.id} error=#{e.message}")
      rescue StandardError => e
        Rails.logger.warn("[Expo2026Campaign] Failed to link only event rich menu: event_line_user_id=#{event_line_user&.id} error=#{e.class}: #{e.message}")
      end

      def body(key)
        {
          "size": {
            "width": 2500,
            "height": 1686
          },
          "selected": true,
          "name": key,
          "chatBarText": I18n.t("user_bot.guest.rich_menu_bar", locale: LOCALE),
          "areas": [
            {
              "bounds": {
                "x": 0,
                "y": 0,
                "width": 1666,
                "height": 1686
              },
              "action": LineActions::Uri.template(
                label: "EXPO 2026",
                url: Rails.application.routes.url_helpers.event_url(slug: EVENT_SLUG)
              )
            },
            {
              "bounds": {
                "x": 1666,
                "y": 0,
                "width": 834,
                "height": 843
              },
              "action": LineActions::Uri.template(
                label: "ユーザーログイン",
                url: LiffRouting.liff_url(:users_connect, LOCALE)
              )
            },
            {
              "bounds": {
                "x": 1666,
                "y": 843,
                "width": 834,
                "height": 843
              },
              "action": LineActions::Uri.template(
                label: "ユーザー登録",
                url: LiffRouting.liff_url(:users_sign_up, LOCALE)
              )
            }
          ]
        }
      end
    end
  end
end

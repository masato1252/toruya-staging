# frozen_string_literal: true

require "line_client"

module RichMenus
  class LinkImage < ActiveInteraction::Base
    object :social_account
    object :social_rich_menu

    def execute
      response = ::LineClient.create_rich_menu_image(
        social_account: social_account,
        rich_menu_id: social_rich_menu.social_rich_menu_id,
        file_path: file_url_or_path
      )

      return response if response.is_a?(Net::HTTPOK)

      log_error(response)
      response
    end

    private

    def file_url_or_path
      return social_rich_menu.image.url if social_rich_menu.image.attached?

      build_default_image_path
    end

    def build_default_image_path
      filename = if social_rich_menu.social_name.match?(/[0-9]/)
        SocialAccounts::RichMenus::CustomerReservations::KEY
      else
        social_rich_menu.social_name
      end

      File.join(
        Rails.root,
        "app",
        "assets",
        "images",
        "rich_menus",
        *locale_path_segment,
        "#{filename}.png"
      )
    end

    def locale_path_segment
      social_account.user.locale == :tw ? ["tw"] : []
    end

    def log_error(response)
      error_data = { response: response.body, url: file_url_or_path }

      if social_rich_menu.image.attached?
        error_data[:base64_image] = Base64.encode64(
          URI.open(file_url_or_path) { |io| io.read }
        )
      end

      Rollbar.error("Invalid Rich Menu image", error_data)
    end
  end
end

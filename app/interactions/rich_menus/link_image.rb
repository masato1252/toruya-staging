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

      unless response.is_a?(Net::HTTPOK)
        if social_rich_menu.image.attached?
          base64_image = Base64.encode64(URI.open(file_url_or_path) { |io| io.read })
          Rollbar.error("Invalid Rich Menu image", response: response.body, url: file_url_or_path, base64_image: base64_image)
        else
          Rollbar.error("Invalid Rich Menu image", response: response.body, url: file_url_or_path)
        end
      end

      response
    end

    private

    def file_url_or_path
      if social_rich_menu.image.attached?
        social_rich_menu.image.url
      elsif social_rich_menu.social_name.match?(/[0-9]/)
        if social_account.user.locale == :tw
          File.join(Rails.root, "app", "assets", "images", "rich_menus", "tw", "#{SocialAccounts::RichMenus::CustomerReservations::KEY}.png")
        else
          File.join(Rails.root, "app", "assets", "images", "rich_menus", "#{SocialAccounts::RichMenus::CustomerReservations::KEY}.png")
        end
      else
        File.join(Rails.root, "app", "assets", "images", "rich_menus", "#{social_rich_menu.social_name}.png")
      end
    end
  end
end
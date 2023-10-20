# frozen_string_literal: true

require "user_bot_social_account"
require "line_client"

module RichMenus
  class ToruyaOfficialCreate < ActiveInteraction::Base
    hash :body, strip: false
    string :key
    string :internal_name
    string :bar_label
    boolean :default_menu, default: false

    def execute
      return unless Rails.env.production?

      SocialRichMenu.transaction do
        SocialRichMenu.where(social_name: key).each do |rich_menu|
          compose(RichMenus::Delete, social_rich_menu: rich_menu)
        end

        response = ::LineClient.create_rich_menu(social_account: UserBotSocialAccount, body: body)

        if response.is_a?(Net::HTTPOK)
          rich_menu_id = JSON.parse(response.body)["richMenuId"]
          # Note: You cannot replace an image attached to a rich menu. To update your rich menu image,
          # create a new rich menu object and upload another image.
          ::LineClient.create_rich_menu_image(social_account: UserBotSocialAccount, rich_menu_id: rich_menu_id, file: rich_menu_file)

          rich_menu = SocialRichMenu.create(
            social_rich_menu_id: rich_menu_id,
            social_name: key,
            body: body,
            internal_name: internal_name,
            bar_label: bar_label,
            default: default_menu
          )

          ::LineClient.set_default_rich_menu(rich_menu) if default_menu

          # Link rich menu to social users
          SocialUser.where(social_rich_menu_key: key).find_each do |social_user|
            RichMenus::Connect.run(social_target: social_user, social_rich_menu: rich_menu)
          end
        else
          # raise response.error
        end
      end
    end

    private

    def rich_menu_file_path
      File.join(Rails.root, "app", "assets", "images", "rich_menus", "#{key}.png")
    end
  end
end

# frozen_string_literal: true

require "user_bot_social_account"
require "line_client"

module RichMenus
  class Create < ActiveInteraction::Base
    object :social_account, default: nil
    hash :body, strip: false
    string :key
    boolean :default_menu, default: false

    def execute
      return unless Rails.env.production?

      SocialRichMenu.transaction do
        if social_account
          social_account.social_rich_menus.where(social_name: key).each do |rich_menu|
            compose(RichMenus::Delete, social_rich_menu: rich_menu)
          end
        else
          SocialRichMenu.where(social_name: key).each do |rich_menu|
            compose(RichMenus::Delete, social_rich_menu: rich_menu)
          end
        end

        response = ::LineClient.create_rich_menu(
          social_account: social_account_object,
          body: body
        )

        if response.is_a?(Net::HTTPOK)
          rich_menu_id = JSON.parse(response.body)["richMenuId"]
          # Note: You cannot replace an image attached to a rich menu. To update your rich menu image,
          # create a new rich menu object and upload another image.
          ::LineClient.create_rich_menu_image(social_account: social_account_object, rich_menu_id: rich_menu_id, file_path: rich_menu_file_path)

          rich_menu = SocialRichMenu.create(
            social_account: social_account,
            social_rich_menu_id: rich_menu_id,
            social_name: key
          )

          if default_menu
            ::LineClient.set_default_rich_menu(rich_menu)
          end

          # Link rich menu to social users or social customer
          SocialUser.where(social_rich_menu_key: key).find_each do |social_user|
            RichMenus::Connect.run(social_target: social_user, social_rich_menu: rich_menu)
          end

          if social_account
            social_account.social_customers.where(social_rich_menu_key: key).find_each do |social_customer|
              RichMenus::Connect.run(social_target: social_customer, social_rich_menu: rich_menu)
            end
          end
        else
          # raise response.error
        end
      end
    end

    private

    def social_account_object
      social_account || UserBotSocialAccount
    end

    def rich_menu_file_path
      File.join(Rails.root, "app", "assets", "images", "rich_menus", "#{key}.png")
    end
  end
end

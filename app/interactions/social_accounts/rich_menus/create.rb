module SocialAccounts
  module RichMenus
    class Create < ActiveInteraction::Base
      object :social_account, default: nil
      hash :body, strip: false
      string :key
      boolean :default_menu, default: false

      def execute
        if rich_menu = social_account.social_rich_menus.find_by(social_name: key)
          compose(SocialAccounts::RichMenus::Delete, social_rich_menu: rich_menu)
        end

        response = LineClient.create_rich_menu(
          social_account: social_account,
          body: body
        )

        if response.is_a?(Net::HTTPOK)
          rich_menu_id = JSON.parse(response.body)["richMenuId"]
          # Note: You cannot replace an image attached to a rich menu. To update your rich menu image,
          # create a new rich menu object and upload another image.
          LineClient.create_rich_menu_image(social_account: social_account, rich_menu_id: rich_menu_id, file_path: rich_menu_file_path)

          rich_menu = SocialRichMenu.create(
            social_account: social_account,
            social_rich_menu_id: rich_menu_id,
            social_name: key
          )

          if default_menu
            LineClient.set_default_rich_menu(rich_menu)
          end
        end
      end

      private

      def rich_menu_file_path
        File.join(Rails.root, "app", "assets", "images", "rich_menus", "#{key}.png")
      end
    end
  end
end

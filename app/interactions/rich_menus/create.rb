# frozen_string_literal: true

require "user_bot_social_account"
require "tw_user_bot_social_account"
require "line_client"

module RichMenus
  class Create < ActiveInteraction::Base
    object :social_account
    string :internal_name
    string :bar_label
    hash :body, strip: false
    string :key
    boolean :default_menu, default: false
    boolean :current, default: false
    file :image, default: nil

    def execute
      if Rails.env.development?
        rich_menu = SocialRichMenu.create(
          social_account: social_account,
          social_rich_menu_id: SecureRandom.uuid,
          social_name: key,
          body: body,
          internal_name: internal_name,
          bar_label: bar_label,
          locale: user.locale
        )
        rich_menu.image.attach(io: image, filename: File.basename(image.path)) if image
        set_default_and_current(rich_menu)

        return
      end
      return unless Rails.env.production?

      response = ::LineClient.create_rich_menu(social_account: social_account, body: body)

      if response.is_a?(Net::HTTPOK)
        rich_menu_id = JSON.parse(response.body)["richMenuId"]
        # Note: You cannot replace an image attached to a rich menu. To update your rich menu image,
        # create a new rich menu object and upload another image.

        rich_menu = SocialRichMenu.create(
          social_account: social_account,
          social_rich_menu_id: rich_menu_id,
          social_name: key,
          body: body,
          internal_name: internal_name,
          bar_label: bar_label,
          locale: user.locale
        )

        rich_menu.image.attach(io: image, filename: File.basename(image.path)) if image
        image_response = compose(::RichMenus::LinkImage, social_account: social_account, social_rich_menu: rich_menu)

        if image_response.is_a?(Net::HTTPOK)
          set_default_and_current(rich_menu)
        else
          if image
            width = RichMenus::Body::LAYOUT_TYPES.dig(rich_menu.layout_type, :size, :width)
            height = RichMenus::Body::LAYOUT_TYPES.dig(rich_menu.layout_type, :size, :height)

            resized_image = ImageProcessing::MiniMagick.source(image).resize_to_fit(width, height).call
            rich_menu.image.attach(io: resized_image, filename: File.basename(image.path))
            resize_image_response = compose(::RichMenus::LinkImage, social_account: social_account, social_rich_menu: rich_menu)

            if resize_image_response.is_a?(Net::HTTPOK)
              set_default_and_current(rich_menu)
              return
            end
          end

          compose(RichMenus::Delete, social_rich_menu: rich_menu)
          errors.add(:image, :invalid)
        end
      else
        Rollbar.error("Create Rich Menu failed", body: response.body, response: response)
        errors.add(:social_account, :something_wrong)
      end
    end

    private

    def user
      @user ||= social_account.user
    end

    def single_rich_menu
      return @single_rich_menu if defined?(@single_rich_menu)

      @single_rich_menu = !social_account.social_rich_menus.where.not(social_name: key).exists?
    end

    def set_default_and_current(rich_menu)
      if default_menu || single_rich_menu
        RichMenus::SetDefault.run(social_rich_menu: rich_menu)
      end

      if current || single_rich_menu
        RichMenus::SetCurrent.run(social_rich_menu: rich_menu)
      end

      social_account.social_rich_menus.where(social_name: key).where.not(id: rich_menu.id).each do |rich_menu|
        RichMenus::Delete.perform_at(schedule_at: 60.minutes.from_now, social_rich_menu: rich_menu)
      end
    end
  end
end
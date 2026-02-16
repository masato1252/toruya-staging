# frozen_string_literal: true
require "line_client"

module RichMenus
  class Delete < ActiveInteraction::Base
    object :social_rich_menu

    def execute
      if Rails.env.development?
        social_rich_menu.destroy
      elsif social_rich_menu.social_rich_menu_id.blank?
        # LINE API上にリッチメニューが存在しない（IDが空）場合はDBレコードのみ削除
        social_rich_menu.image.purge_later if social_rich_menu.image.attached?
        social_rich_menu.destroy
      else
        response = ::LineClient.delete_rich_menu(social_rich_menu)

        if response.is_a?(Net::HTTPOK) || response.is_a?(Net::HTTPNotFound)
          social_rich_menu.image.purge_later if social_rich_menu.image.attached?
          social_rich_menu.destroy
        else
          errors.add(:social_rich_menu, :delete_failed)
        end
      end
    end
  end
end

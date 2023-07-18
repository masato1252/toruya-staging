# frozen_string_literal: true

require "line_client"

module SocialAccounts
  module RichMenus
    class Delete < ActiveInteraction::Base
      object :social_rich_menu

      def execute
        response = nil

        if Rails.env.development?
          social_rich_menu.destroy
        else
          response = ::LineClient.delete_rich_menu(social_rich_menu)

          if response.is_a?(Net::HTTPOK)
            social_rich_menu.destroy
          else
            errors.add(:social_rich_menu, :delete_failed)
          end
        end
      end
    end
  end
end

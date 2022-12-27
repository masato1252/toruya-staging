# frozen_string_literal: true

require "line_client"

module SocialAccounts
  module RichMenus
    class Delete < ActiveInteraction::Base
      object :social_rich_menu

      def execute
        response = nil
        unless Rails.env.development?
          response = ::LineClient.delete_rich_menu(social_rich_menu)
        end

        social_rich_menu.destroy if response.is_a?(Net::HTTPOK)
      end
    end
  end
end

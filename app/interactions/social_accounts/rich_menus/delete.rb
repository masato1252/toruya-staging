# frozen_string_literal: true

require "line_client"

module SocialAccounts
  module RichMenus
    class Delete < ActiveInteraction::Base
      object :social_rich_menu

      def execute
        ::LineClient.delete_rich_menu(social_rich_menu) unless Rails.env.development?
        social_rich_menu.destroy
      end
    end
  end
end

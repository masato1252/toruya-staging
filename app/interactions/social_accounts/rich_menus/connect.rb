# frozen_string_literal: true

require "line_client"

module SocialAccounts
  module RichMenus
    class Connect < ActiveInteraction::Base
      object :social_rich_menu

      def execute
        social_rich_menu.account.social_customers.find_each do |social_customer|
          ::RichMenus::Connect.perform_later(social_target: social_customer, social_rich_menu: social_rich_menu)
        end
      end
    end
  end
end

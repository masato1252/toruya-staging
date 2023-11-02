# frozen_string_literal: true

require "line_client"

module RichMenus
  class Unlink < ActiveInteraction::Base
    object :social_rich_menu

    def execute
      social_rich_menu.update(current: nil)
      social_rich_menu.account.social_customers.find_each do |social_customer|
        LineClient.unlink_rich_menu(social_customer: social_customer)
      end
    end
  end
end

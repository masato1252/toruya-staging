# frozen_string_literal: true

require "line_client"

module SocialUsers
  class Disconnect < ActiveInteraction::Base
    object :social_user

    def execute
      return unless user

      social_user.update!(user_id: nil, social_rich_menu_key: UserBotLines::RichMenus::Guest::KEY)

      LineClient.unlink_rich_menu(social_customer: social_user)
    end

    private

    def user
      @user ||= social_user.user
    end
  end
end

# frozen_string_literal: true

require "line_client"

module SocialUsers
  class Initialize < ActiveInteraction::Base
    SOCIAL_USER_NAME_KEY = "displayName".freeze
    SOCIAL_USER_PICTURE_KEY = "pictureUrl".freeze

    string :social_service_user_id

    def execute
      social_user =
        begin
          SocialUser.transaction do
            SocialUser
              .create_with(social_rich_menu_key: UserBotLines::RichMenus::Guest::KEY)
              .find_or_create_by(social_service_user_id: social_service_user_id)
          end
        rescue ActiveRecord::RecordNotUnique
          retry
        end

      response = LineClient.profile(social_user)

      if response.is_a?(Net::HTTPOK)
        body = JSON.parse(response.body)
        social_user.update(social_user_name: body[SOCIAL_USER_NAME_KEY], social_user_picture_url: body[SOCIAL_USER_PICTURE_KEY])
      end

      social_user
    end
  end
end

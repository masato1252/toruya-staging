# frozen_string_literal: true

require "line_client"

module SocialUsers
  class Initialize < ActiveInteraction::Base
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

      LineProfileJob.perform_later(social_user)

      social_user
    end
  end
end

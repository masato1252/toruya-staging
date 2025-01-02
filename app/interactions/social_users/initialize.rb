# frozen_string_literal: true

require "line_client"

module SocialUsers
  class Initialize < ActiveInteraction::Base
    string :social_service_user_id
    string :who

    def execute
      social_user =
        begin
          SocialUser.transaction do
            SocialUser
              .create_with(
                social_rich_menu_key: UserBotLines::RichMenus::Guest::KEY,
                locale: who == CallbacksController::TW_TORUYA_USER ? "tw" : "ja"
              )
              .order("id")
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

# frozen_string_literal: true

require "line_client"

module SocialUsers
  class Initialize < ActiveInteraction::Base
    string :social_service_user_id
    string :who, default: nil
    string :email, default: nil

    def execute
      _who = if who.nil?
        determine_user_type(social_service_user_id)
      else
        who
      end

      social_user =
        begin
          SocialUser.transaction do
            SocialUser
              .create_with(
                social_rich_menu_key: UserBotLines::RichMenus::Guest::KEY,
                locale: _who == CallbacksController::TW_TORUYA_USER ? "tw" : "ja"
              )
              .order("id")
              .find_or_create_by(social_service_user_id: social_service_user_id)
          end
        rescue ActiveRecord::RecordNotUnique
          retry
        end

      social_user.update(email: email) if email.present?

      LineProfileJob.perform_later(social_user)

      social_user
    end

    private

    def determine_user_type(user_id)
      # Try UserBotSocialAccount first
      response = UserBotSocialAccount.client.get_profile(user_id)
      return CallbacksController::TORUYA_USER if response.is_a?(Net::HTTPOK)

      # Try TwUserBotSocialAccount if first attempt failed
      response = TwUserBotSocialAccount.client.get_profile(user_id)
      return CallbacksController::TW_TORUYA_USER if response.is_a?(Net::HTTPOK)

      nil
    end
  end
end

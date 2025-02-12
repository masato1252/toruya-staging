# frozen_string_literal: true

require "line_client"

module SocialUsers
  class FromOmniauth < ActiveInteraction::Base
    object :auth, class: OmniAuth::AuthHash
    string :who

    def execute
      compose(SocialUsers::Initialize, social_service_user_id: auth.uid, who: who, email: email)
    end

    private

    def email
      JWT.decode(auth.info.access_token["id_token"], secret)[0]["email"]
    rescue => e
      nil
    end

    def secret
      if who == CallbacksController::TORUYA_USER
        Rails.application.secrets[:ja][:toruya_line_login_secret]
      else
        Rails.application.secrets[:tw][:toruya_line_login_secret]
      end
    end
  end
end

# frozen_string_literal: true

require "line_client"

module SocialUsers
  class FromOmniauth < ActiveInteraction::Base
    object :auth, class: OmniAuth::AuthHash
    string :who

    def execute
      compose(SocialUsers::Initialize, social_service_user_id: auth.uid, who: who)
    end
  end
end

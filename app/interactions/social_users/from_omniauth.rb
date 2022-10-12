# frozen_string_literal: true

require "line_client"

module SocialUsers
  class FromOmniauth < ActiveInteraction::Base
    object :auth, class: OmniAuth::AuthHash

    def execute
      compose(SocialUsers::Initialize, social_service_user_id: auth.uid)
    end
  end
end

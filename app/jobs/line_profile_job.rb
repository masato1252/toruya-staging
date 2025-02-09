# frozen_string_literal: true

require "line_client"

class LineProfileJob < ApplicationJob
  SOCIAL_USER_NAME_KEY = "displayName".freeze
  SOCIAL_USER_PICTURE_KEY = "pictureUrl".freeze

  queue_as :low_priority

  def perform(social_user_or_customer)
    response = LineClient.profile(social_user_or_customer)

    if response.is_a?(Net::HTTPOK)
      body = JSON.parse(response.body)

      social_user_or_customer.update(
        social_user_name: body[SOCIAL_USER_NAME_KEY],
        social_user_picture_url: body[SOCIAL_USER_PICTURE_KEY]
      )
    end
  end
end

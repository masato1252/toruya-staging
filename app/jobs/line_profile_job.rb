# frozen_string_literal: true

require "line_client"

class LineProfileJob < ApplicationJob
  SOCIAL_USER_NAME_KEY = "displayName".freeze
  SOCIAL_USER_PICTURE_KEY = "pictureUrl".freeze
  SOCIAL_USER_LOCALE_KEY = "language".freeze

  queue_as :low_priority

  def perform(social_user_or_customer)
    response = LineClient.profile(social_user_or_customer)

    if response.is_a?(Net::HTTPOK)
      body = JSON.parse(response.body)
      locale =
        case body[SOCIAL_USER_LOCALE_KEY]
        when "zh-Hant"
          "tw"
        else
          body[SOCIAL_USER_LOCALE_KEY]
        end

      social_user_or_customer.update(
        social_user_name: body[SOCIAL_USER_NAME_KEY],
        social_user_picture_url: body[SOCIAL_USER_PICTURE_KEY],
        locale: locale
      )
    end
  end
end

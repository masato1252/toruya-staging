# frozen_string_literal: true

class CustomMessageSerializer
  include JSONAPI::Serializer
  attribute :id, :content

  attribute :picture_url do |custom_message|
    if custom_message.picture.attached?
      Rails.application.routes.url_helpers.url_for(custom_message.picture)
    end
  end
end

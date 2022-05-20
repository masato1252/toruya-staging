# frozen_string_literal: true

class CustomMessageSerializer
  include JSONAPI::Serializer
  attribute :id, :content, :after_days, :content_type, :flex_template, :scenario, :service_id, :service_type

  attribute :picture_url do |custom_message|
    if custom_message.picture.attached?
      Rails.application.routes.url_helpers.url_for(custom_message.picture.variant(combine_options: { resize: "640x416", flatten: true }))
    end
  end

  attribute :flex_attributes do |custom_message|
    if custom_message.content_type == CustomMessage::FLEX_TYPE
      JSON.parse(custom_message.content)
    else
      {}
    end
  end
end

# frozen_string_literal: true

class SocialUserMessageSerializer
  include JSONAPI::Serializer
  attribute :id, :created_at, :message_type

  attribute :customer_id do |message|
    message.social_user.social_service_user_id
  end

  attribute :text do |message|
    message.raw_content
  end

  attribute :readed do |message|
    message.readed_at.present?
  end

  attribute :sent do |message|
    true
  end

  attribute :formatted_created_at do |message|
    I18n.l(message.created_at, format: :long_date_with_wday)
  end
end

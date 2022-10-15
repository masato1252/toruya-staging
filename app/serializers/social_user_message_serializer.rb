# frozen_string_literal: true

class SocialUserMessageSerializer
  include JSONAPI::Serializer
  attribute :id, :created_at, :message_type, :content_type

  attribute :customer_id do |message|
    message.social_user.social_service_user_id
  end

  attribute :is_image do |message|
    begin
      JSON.parse(message.raw_content)
      message.content_type != SocialUserMessages::Create::FLEX_TYPE
    rescue TypeError, JSON::ParserError => e
      false
    end
  end

  attribute :text do |message|
    begin
      content = JSON.parse(message.raw_content)
      if message.image.attached?
        content["previewImageUrl"] = Images::Process.run!(image: message.image, resize: "750")
      end

      case message.content_type
      when SocialUserMessages::Create::FLEX_TYPE
        content["altText"]
      else
        content
      end
    rescue TypeError, JSON::ParserError
      message.raw_content
    end
  end

  attribute :readed do |message|
    message.readed_at.present?
  end

  attribute :sent do |message|
    message.schedule_at.present? ? message.sent_at.present? : true
  end

  attribute :formatted_created_at do |message|
    I18n.l(message.sent_at || message.created_at, format: :long_date_with_wday)
  end

  attribute :formatted_schedule_at do |message|
    I18n.l(message.schedule_at, format: :long_date_with_wday) if message.schedule_at
  end
end

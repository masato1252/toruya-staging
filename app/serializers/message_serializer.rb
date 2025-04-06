# frozen_string_literal: true

class MessageSerializer
  include JSONAPI::Serializer
  attribute :id, :created_at, :message_type, :content_type, :channel

  attribute :customer_id do |message|
    message.social_customer&.social_user_id || message.customer_id
  end

  attribute :toruya_customer_id do |message|
    message.social_customer&.customer_id || message.customer_id
  end

  attribute :user_id do |message|
    message.social_customer&.user_id || message.user_id
  end

  attribute :is_image do |message|
    begin
      JSON.parse(message.raw_content)
      message.content_type != SocialMessages::Create::FLEX_TYPE
    rescue JSON::ParserError => e
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
      when SocialMessages::Create::FLEX_TYPE
        content["altText"]
      else
        content
      end
    rescue JSON::ParserError
      message.raw_content
    end
  end

  attribute :readed do |message|
    message.readed_at.present?
  end

  attribute :sent do |message|
    message.sent_at.present?
  end

  attribute :formatted_created_at do |message|
    I18n.l(message.sent_at || message.created_at, format: :long_date_with_wday)
  end

  attribute :formatted_schedule_at do |message|
    I18n.l(message.schedule_at, format: :long_date_with_wday) if message.schedule_at
  end

  attribute :staff_name do |message|
    message.staff&.name
  end
end

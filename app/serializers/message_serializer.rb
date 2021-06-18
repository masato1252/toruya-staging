# frozen_string_literal: true

class MessageSerializer
  include JSONAPI::Serializer
  attribute :id, :created_at, :message_type

  attribute :customer_id do |message|
    message.social_customer.social_user_id
  end

  attribute :toruya_customer_id do |message|
    message.social_customer.customer_id
  end

  attribute :user_id do |message|
    message.social_customer.user_id
  end

  attribute :is_image do |message|
    JSON.parse(json)
    return true
  rescue JSON::ParserError => e
    return false
  end

  attribute :text do |message|
    begin
      content = JSON.parse(message.raw_content)
      if message.image.attached?
        content["previewImageUrl"] = Rails.application.routes.url_helpers.url_for(message.image.variant(combine_options: { resize: "750", flatten: true }))
      end

      content
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
end

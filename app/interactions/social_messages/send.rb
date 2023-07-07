require "line_client"

module SocialMessages
  class Send < ActiveInteraction::Base
    object :social_message

    def execute
      response =
        case content_type
        when SocialMessages::Create::TEXT_TYPE
          LineClient.send(social_customer, content)
        when SocialMessages::Create::VIDEO_TYPE
          LineClient.send_video(social_customer, content)
        when SocialMessages::Create::IMAGE_TYPE
          LineClient.send_image(social_customer, content)
        when SocialMessages::Create::FLEX_TYPE
          LineClient.flex(social_customer, content)
        end

      if response.code == "200"
        social_message.update(sent_at: Time.current)
      elsif response.code == "401"
        errors.add(:social_message, :sent_failed_line_settings_wrong)
      elsif response.code == "429"
        Notifiers::Users::Notifications::LineReachedMonthlyLimit.perform_debounce(receiver: social_customer.user.social_user)

        errors.add(:social_message, :sent_failed_line_limit)
      else
        errors.add(:social_message, :sent_failed)
      end
    rescue ArgumentError
      errors.add(:social_message, :sent_failed_line_settings_wrong)
    end

    private

    def social_customer
      social_message.social_customer
    end

    def content
      social_message.raw_content
    end

    def content_type
      social_message.content_type
    end
  end
end

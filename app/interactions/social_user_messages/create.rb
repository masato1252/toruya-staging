require "line_client"
require "webpush_client"

module SocialUserMessages
  class Create < ActiveInteraction::Base
    object :social_user
    string :content
    boolean :readed
    integer :message_type

    def execute
      message = SocialUserMessage.create(
        social_user: social_user,
        raw_content: content,
        readed_at: readed ? Time.zone.now : nil,
        message_type: message_type
      )

      if message.errors.present?
        errors.merge!(message.errors)
      elsif message_type == SocialMessage.message_types[:bot] || message_type == SocialMessage.message_types[:admin]
        LineClient.send(social_user, content)
      end

      message
    end
  end
end

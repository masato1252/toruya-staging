# frozen_string_literal: true

require "line_client"
require "webpush_client"

module SocialUserMessages
  class CreateAiMessage < ActiveInteraction::Base
    object :social_user
    string :ai_question
    string :ai_response
    string :ai_uid

    def execute
      ai_question_message = SocialUserMessage.create(
        social_user: social_user,
        raw_content: ai_question,
        readed_at: Time.current,
        message_type: SocialUserMessage.message_types[:user_ai_question],
        content_type: ::SocialUserMessages::Create::TEXT_TYPE,
        ai_uid: ai_uid
      )

      ai_response_message = SocialUserMessage.create(
        social_user: social_user,
        raw_content: ai_response,
        readed_at: Time.current,
        message_type: SocialUserMessage.message_types[:user_ai_response],
        content_type: SocialUserMessages::Create::TEXT_TYPE,
        ai_uid: ai_uid
      )

      {
        ai_question_message: ai_question_message,
        ai_response_message: ai_response_message
      }
    end
  end
end

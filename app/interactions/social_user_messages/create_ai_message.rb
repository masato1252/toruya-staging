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

      google_worksheet = Google::Drive.spreadsheet(gid: 1696867616)
      new_row_number = google_worksheet.num_rows + 1
      new_row_data = [ ai_question, ai_response, ai_uid ]
      new_row_data.each_with_index do |data, index|
        google_worksheet[new_row_number, index + 1] = data
      end
      google_worksheet.save

      {
        ai_question_message: ai_question_message,
        ai_response_message: ai_response_message
      }
    end
  end
end

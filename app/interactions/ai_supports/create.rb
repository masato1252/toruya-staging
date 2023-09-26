# frozen_string_literal: true

module AiSupports
  class Create < ActiveInteraction::Base
    object :social_user
    string :user_id
    string :question
    string :ai_uid

    def execute
      outcome = Ai::Query.run(user_id: user_id, question: question)
      SocialUserMessages::CreateAiMessage.run(
        social_user: social_user,
        ai_question: question,
        ai_response: outcome.result[:message],
        ai_uid: ai_uid
      )
    end
  end
end

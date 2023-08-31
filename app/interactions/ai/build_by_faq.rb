# frozen_string_literal: true

module Ai
  class BuildByFaq < ActiveInteraction::Base
    string :user_id
    string :question
    string :answer

    def execute
      document_text = <<-EOF
        QUESTION: #{question}\n
        ANSWER: #{answer}
      EOF

      faq = AiFaq.create!(user_id: user_id, question: question, answer: answer)
      AI_BUILD.build_by_text(user_id, "#{user_id}-#{faq.id}", document_text)
    end
  end
end

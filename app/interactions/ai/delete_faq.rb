# frozen_string_literal: true

module Ai
  class DeleteFaq < ActiveInteraction::Base
    string :user_id
    object :faq, class: AiFaq

    def execute
      AI_BUILD.delete_doc(user_id, "#{user_id}-#{faq.id}")
      faq.destroy
    end
  end
end

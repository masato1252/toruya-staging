# frozen_string_literal: true

module CustomMessages
  class Update < ActiveInteraction::Base
    object :message, class: CustomMessage
    string :template
    integer :after_days, default: nil

    def execute
      message.content = template
      message.after_days = after_days
      message.save
      message
    end
  end
end

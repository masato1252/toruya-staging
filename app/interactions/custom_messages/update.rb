# frozen_string_literal: true

module CustomMessages
  class Update < ActiveInteraction::Base
    object :service, class: ApplicationRecord
    string :template
    string :scenario

    def execute
      message = CustomMessage.find_or_initialize_by(service: service, scenario: scenario)
      message.content = template
      message.save
      message
    end
  end
end

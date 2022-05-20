# frozen_string_literal: true

module CustomMessages
  module Users
    class Template < ActiveInteraction::Base
      USER_SIGN_UP = "user_sign_up"
      SCENARIOS = [USER_SIGN_UP].freeze

      string :scenario

      validate :validate_product_type

      def execute
        message = CustomMessage.find_by(scenario: scenario, after_days: nil)
        return message.content if message

        case scenario
        when USER_SIGN_UP
          # no default template
        end
      end
    end
  end
end

# frozen_string_literal: true

module CustomMessages
  module Users
    class Next < ActiveInteraction::Base
      object :custom_message, default: nil
      string :scenario, default: nil
      object :receiver, class: User
      boolean :schedule_right_away, default: false

      validate :validate_next_scenario
      validates :scenario, inclusion: { in: [CustomMessages::Users::Template::USER_SIGN_UP] }, allow_nil: true

      def execute
        if schedule_right_away
          send_schedule_message(custom_message)
        elsif next_custom_messages.exists?
          next_custom_messages.find_each do |next_custom_message|
            send_schedule_message(next_custom_message)
          end
        end
      end

      private

      def send_schedule_message(message)
        schedule_at = scenario_start_at.advance(days: message.after_days).change(hour: 9)

        # TODO: think about change case
        if schedule_at > Time.current || message.after_days == 0
          Notifiers::Users::CustomMessages::Send.perform_at(
            schedule_at: schedule_at,
            custom_message: message,
            receiver: receiver
          )
        end
      end

      def next_custom_messages
        return @next_custom_messages if defined?(@next_custom_messages)

        @next_custom_messages = CustomMessage.scenario_of(nil, user_scenario)
        after_days = @next_custom_messages.where("after_days > ?", custom_message&.after_days || -100).first&.after_days

        @next_custom_messages =
          if after_days
            @next_custom_messages.where(after_days: after_days)
          else
            @next_custom_messages.none
          end

        @next_custom_messages
      end

      def validate_next_scenario
        if custom_message && scenario
          errors.add(:custom_message, :invalid_params)
        end

        if !custom_message && !scenario
          errors.add(:custom_message, :invalid_params)
        end
      end

      def scenario_start_at
        case user_scenario
        when CustomMessages::Users::Template::USER_SIGN_UP
          receiver.created_at
        end
      end

      def user_scenario
        scenario || custom_message.scenario
      end
    end
  end
end

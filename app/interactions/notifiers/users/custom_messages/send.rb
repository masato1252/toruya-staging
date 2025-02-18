# frozen_string_literal: true

require "translator"

module Notifiers
  module Users
    module CustomMessages
      class Send < Base
        deliver_by_priority [:line, :sms, :email]

        object :custom_message
        time :scenario_start_at, default: nil

        validate :receiver_should_be_user
        validate :validate_schedule_conditions

        def message
          compose(::CustomMessages::ReceiverContent, custom_message: custom_message, receiver: receiver, variable_source: custom_message.service)
        end

        def content_type
          custom_message.content_type
        end

        def deliverable
          if custom_message.scenario == ::CustomMessages::Users::Template::NO_LINE_SETTINGS
            !receiver.social_account&.line_settings_verified? && expected_schedule_time && !custom_message.ever_sent_to_user(receiver)
          else
            expected_schedule_time && !custom_message.ever_sent_to_user(receiver)
          end
        end

        def message_scenario
          custom_message.scenario
        end

        def nth_time_message
          custom_message.nth_time
        end

        def execute
          super

          ::CustomMessages::Users::Next.run(
            custom_message: custom_message,
            receiver: receiver
          )
        end

        def custom_message_id
          custom_message.id
        end

        private

        def expected_schedule_time
          if schedule_at && custom_message.after_days && scenario_start_at
            expected_schedule_at = scenario_start_at.advance(days: custom_message.after_days).change(hour: ::CustomMessages::Users::Next::DEFAULT_NOTIFICATION_HOUR)
            return expected_schedule_at.utc.to_i == schedule_at.change(min: 0, sec: 0).utc.to_i
          end

          true # real time
        end

        def validate_schedule_conditions
          if schedule_at.nil? != scenario_start_at.nil?
            errors.add(:schedule_at, :schedule_at_and_scenario_start_at_need_both)
          end
        end
      end
    end
  end
end

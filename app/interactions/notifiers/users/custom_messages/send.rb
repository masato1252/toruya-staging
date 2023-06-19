# frozen_string_literal: true

require "translator"

module Notifiers
  module Users
    module CustomMessages
      class Send < Base
        deliver_by :line

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
          expected_schedule_time
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

        private

        def expected_schedule_time
          if schedule_at && custom_message.after_days && scenario_start_at
            expected_schedule_at = scenario_start_at.advance(days: custom_message.after_days).change(hour: 9)
            return expected_schedule_at.to_fs(:iso8601) == schedule_at.to_fs(:iso8601)
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

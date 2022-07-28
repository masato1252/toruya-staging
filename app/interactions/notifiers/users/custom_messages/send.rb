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
          compose(::CustomMessages::ReceiverContent, custom_message: custom_message, receiver: receiver)
        end

        def content_type
          custom_message.content_type
        end

        def deliverable
          expected_schedule_time &&
            custom_message.receiver_ids.exclude?(receiver.id.to_s)
        end

        def execute
          super

          if errors.blank?
            custom_message.with_lock do
              custom_message.update(receiver_ids: custom_message.receiver_ids.push(receiver.id).map(&:to_s).uniq) if deliverable
            end
          end

          ::CustomMessages::Users::Next.run(
            custom_message: custom_message,
            receiver: receiver
          )
        end

        private

        def expected_schedule_time
          if schedule_at && custom_message.after_days && scenario_start_at
            expected_schedule_at = scenario_start_at.advance(days: custom_message.after_days).change(hour: 9)
            return expected_schedule_at.to_s(:iso8601) == schedule_at.to_s(:iso8601)
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

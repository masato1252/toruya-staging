# frozen_string_literal: true

require "translator"

module Notifiers
  module Customers
    module CustomMessages
      class ReservationReminder < Base
        deliver_by :line

        object :custom_message
        object :reservation

        validate :receiver_should_be_customer
        validate :service_should_be_booking_page

        def message
          compose(::CustomMessages::ReceiverContent, custom_message: custom_message, receiver: receiver)
        end

        def deliverable
          expected_schedule_time && reservation.notifiable?
        end

        private

        def expected_schedule_time
          if schedule_at && custom_message.before_minutes
            expected_schedule_at = reservation.start_time.advance(minutes: -custom_message.before_minutes)
            return expected_schedule_at.to_s(:iso8601) == schedule_at.to_s(:iso8601)
          end

          true # real time
        end

        def service_should_be_booking_page
          unless custom_message.service.is_a?(BookingPage)
            errors.add(:custom_message, :is_invalid_service)
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

require "translator"

module Notifiers
  module Customers
    class Broadcast < Base
      object :broadcast

      def message
        if broadcast.reservation_customers?
          reservation = Reservation.where(id: broadcast.target_ids).first

          Translator.perform(broadcast.content, reservation.message_template_variables(receiver))
        else
          Translator.perform(broadcast.content, { customer_name: receiver.message_name })
        end
      end

      def deliverable
        # It is a broadcast to all the customers in the reservations, not regular marketing broadcast.
        if broadcast.reservation_customers? || broadcast.manual_assignment?
          true
        else
          receiver.reminder_permission
        end
      end
    end
  end
end

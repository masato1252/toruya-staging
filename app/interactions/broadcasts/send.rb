# frozen_string_literal: true

module Broadcasts
  class Send < ActiveInteraction::Base
    object :broadcast
    time :schedule_at, default: nil

    def execute
      broadcast.with_lock do
        return if schedule_at && broadcast.schedule_at.nil?

        # Compare times using UTC timestamps instead of ISO8601 strings
        if schedule_at && broadcast.schedule_at
          # Convert both times to UTC and compare their timestamps
          schedule_time_utc = schedule_at.utc.to_i
          broadcast_time_utc = broadcast.schedule_at.utc.to_i

          # Only process if the scheduled time matches the broadcast's scheduled time
          return if schedule_time_utc != broadcast_time_utc
        end

        return unless broadcast.active?

        customers = compose(Broadcasts::FilterCustomers, broadcast: broadcast)
        customers.each do |customer|
          # Use the application's timezone since this is an immediate job
          Notifiers::Customers::Broadcast.perform_later(receiver: customer, broadcast: broadcast)
        end

        # Record that the broadcast was sent
        broadcast.update(state: :final, sent_at: Time.current, recipients_count: customers.size)
      end
    end
  end
end

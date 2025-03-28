# frozen_string_literal: true

module Broadcasts
  class Activate < ActiveInteraction::Base
    object :broadcast

    def execute
      broadcast.with_lock do
        if broadcast.draft?
          broadcast.active!

          # When updating broadcast, if change broadcast's schedule_at
          # the scheduled job already executed, but the broadcast was draft at that time
          # so broadcast won't be sent to customers
          if broadcast.schedule_at.nil? || broadcast.schedule_at < Time.current
            # Get the user's timezone for proper scheduling
            Time.use_zone(broadcast.user.timezone) do
            # Use the user's timezone for scheduling
            Time.use_zone(broadcast.user.timezone) do
              Broadcasts::Send.perform_at(
                schedule_at: broadcast.schedule_at,
                broadcast: broadcast
              )
            end
          end
        end
      end
    end
  end
end

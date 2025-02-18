# frozen_string_literal: true

module Broadcasts
  class Create < ActiveInteraction::Base
    object :user
    hash :params do
      string :content
      hash :query, strip: false, default: {}
      string :query_type
      time :schedule_at, default: nil
    end

    def execute
      broadcast = user.broadcasts.create(params)

      if broadcast.valid?
        customers = compose(Broadcasts::FilterCustomers, broadcast: broadcast)
        broadcast.update(recipients_count: customers.count)

        # If there's a scheduled time, ensure it's in the user's timezone
        schedule_time = broadcast.schedule_at

        if schedule_time
          # Get the user's timezone
          user_timezone = ::LOCALE_TIME_ZONE[user.locale] || "Asia/Tokyo"

          # Use the user's timezone for scheduling
          Time.use_zone(user_timezone) do
            # Schedule the broadcast ensuring timezone is preserved
            Broadcasts::Send.perform_at(
              schedule_at: schedule_time,
              broadcast: broadcast
            )
          end
        else
          # If there's no scheduled time, send immediately
          Broadcasts::Send.perform_at(
            schedule_at: broadcast.schedule_at,
            broadcast: broadcast
          )
        end
      else
        errors.merge!(broadcast.errors)
      end

      broadcast
    end
  end
end

# frozen_string_literal: true

module Broadcasts
  class Update < ActiveInteraction::Base
    object :broadcast
    string :update_attribute
    hash :params do
      string :content, default: nil
      hash :query, strip: false, default: nil
      string :query_type, default: nil
      time :schedule_at, default: nil
    end

    validate :validate_broadcast
    validate :validate_query

    def execute
      broadcast.update!(params.slice(update_attribute))

      if broadcast.saved_change_to_attribute?(:schedule_at)
        # Get the user's timezone for proper scheduling
        user_timezone = ::LOCALE_TIME_ZONE[broadcast.user.locale] || "Asia/Tokyo"

        # Use the user's timezone for scheduling the broadcast
        Time.use_zone(user_timezone) do
          Broadcasts::Send.perform_at(
            schedule_at: broadcast.schedule_at,
            broadcast: broadcast
          )
        end
      end

      customers = compose(Broadcasts::FilterCustomers, broadcast: broadcast)
      broadcast.update(recipients_count: customers.count)
      broadcast
    end

    private

    def validate_broadcast
      unless broadcast.draft?
        errors.add(:broadcast, :invalid_state)
      end
    end

    def validate_query
      if params.dig(:query, :filters).nil?
        if ["online_service", "online_service_for_active_customers"].include?(params[:query_type])
          errors.add(:broadcast, :service_is_required)
        end

        if ["menu"].include?(params[:query_type])
            errors.add(:broadcast, :menu_is_required)
        end
      end
    end
  end
end

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

    def execute
      broadcast.update!(params.slice(update_attribute))

      if broadcast.saved_change_to_attribute?(:schedule_at)
        Broadcasts::Send.perform_at(schedule_at: broadcast.schedule_at, broadcast: broadcast)
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
  end
end

# frozen_string_literal: true

module Broadcasts
  class Send < ActiveInteraction::Base
    object :broadcast
    time :schedule_at, default: nil

    def execute
      broadcast.with_lock do
        return if schedule_at && schedule_at.to_s(:iso8601) != broadcast.schedule_at.to_s(:iso8601)
        return unless broadcast.active?

        customers = compose(Broadcasts::FilterCustomers, broadcast: broadcast)

        customers.each do |customer|
          Notifiers::Customers::Broadcast.perform_later(receiver: customer, broadcast: broadcast)
        end

        broadcast.update(state: :final, sent_at: Time.current, recipients_count: customers.size)
      end
    end
  end
end

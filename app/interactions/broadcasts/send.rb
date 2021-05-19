# frozen_string_literal: true

module Broadcasts
  class Send < ActiveInteraction::Base
    object :broadcast

    def execute
      broadcast.with_lock do
        return unless broadcast.active?

        customers = compose(Broadcasts::FilterCustomers, broadcast: broadcast)

        customers.find_each do |customer|
          Notifiers::Broadcast.perform_later(receiver: customer, broadcast: broadcast)
        end

        broadcast.update(state: :final, sent_at: Time.current, recipients_count: customers.size)
      end
    end
  end
end

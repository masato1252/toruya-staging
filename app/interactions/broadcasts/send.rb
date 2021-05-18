module Broadcasts
  class Send < ActiveInteraction::Base
    object :broadcast

    def execute
      broadcast.with_lock do
        return if broadcast.draft? || broadcast.sent_at.present?

        customers = compose(Broadcasts::FilterCustomers, broadcast: broadcast)

        customers.find_each do |customer|
          Notifiers::Broadcast.perform_later(receiver: customer, broadcast: broadcast)
        end

        broadcast.update(sent_at: Time.current)
      end
    end
  end
end

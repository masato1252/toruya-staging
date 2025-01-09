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

        Broadcasts::Send.perform_at(schedule_at: broadcast.schedule_at, broadcast: broadcast)
      else
        errors.merge!(broadcast.errors)
      end

      broadcast
    end
  end
end

module Broadcasts
  class Create < ActiveInteraction::Base
    object :user
    hash :params do
      string :content
      hash :query, strip: false
      time :schedule_at, default: nil
    end

    def execute
      broadcast = user.broadcasts.create(params)

      if broadcast.valid?
        Broadcasts::Send.perform_at(schedule_at: broadcast.schedule_at, broadcast: broadcast)
      end

      broadcast
    end
  end
end

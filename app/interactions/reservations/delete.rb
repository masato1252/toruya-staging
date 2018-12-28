module Reservations
  class Delete < ActiveInteraction::Base
    object :reservation

    def execute
      reservation.update(deleted_at: Time.current)
    end
  end
end

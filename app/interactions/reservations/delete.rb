module Reservations
  class Delete < ActiveInteraction::Base
    object :reservation

    def execute
      reservation.update_columns(deleted_at: Time.current)
    end
  end
end

# frozen_string_literal: true

module Reservations
  class Delete < ActiveInteraction::Base
    object :reservation

    def execute
      reservation.transaction do
        reservation.update_columns(deleted_at: Time.current)
        reservation.reservation_customers.update_all(state: :deleted)
      end
    end
  end
end

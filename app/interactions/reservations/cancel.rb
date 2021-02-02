# frozen_string_literal: true

module Reservations
  class Cancel < ActiveInteraction::Base
    object :reservation

    def execute
      reservation.transaction do
        reservation.cancel!
        reservation.reservation_customers.update_all(state: :canceled)
      end
    end
  end
end

# frozen_string_literal: true

class ReservationConfirmationJob < ApplicationJob
  queue_as :high_priority

  def perform(reservation, customer)
    Reservations::Notifications::Confirmation.run!(customer: customer, reservation: reservation)
  end
end

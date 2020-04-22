class ReservationConfirmationJob < ApplicationJob
  queue_as :default

  def perform(reservation, customer)
    Reservations::Notifications::Confirmation.run!(customer: customer, reservation: reservation)
  end
end

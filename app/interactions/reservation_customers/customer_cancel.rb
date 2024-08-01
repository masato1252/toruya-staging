# frozen_string_literal: true

# TODO
# handle ticket
# cancel, deleted, refund
module ReservationCustomers
  class CustomerCancel < ActiveInteraction::Base
    object :reservation_customer
    string :cancel_reason, default: nil

    validate :validate_reservation_state

    def execute
      reservation_customer.with_lock do
        reservation_customer.cancel_reason = cancel_reason
        reservation_customer.customer_canceled!

        if reservation.customers.count == 1
          compose(Reservations::Cancel, reservation: reservation)
        end

        Notifiers::Users::Reservations::CustomerCancel.perform_later(
          receiver: reservation_customer.customer.user,
          customer_name: reservation_customer.customer.name,
          booking_info_url: Utils.url_with_external_browser(Rails.application.routes.url_helpers.booking_url(reservation_customer.slug))
        )
      end
    end

    private

    def reservation
      @reservation ||= reservation_customer.reservation
    end

    def validate_reservation_state
      if !reservation_customer.allow_customer_cancel?
        errors.add(:reservation_customer, :invalid_state)
      end
    end
  end
end

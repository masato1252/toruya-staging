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

        if customer_ticket = reservation_customer.customer_ticket
          compose(Tickets::Revert, consumer: reservation_customer, customer_ticket: customer_ticket)
        end

        if reservation.customers.count.zero?
          reservation.cancel!
        end

        Notifiers::Users::Reservations::CustomerCancel.perform_later(
          receiver: reservation_customer.customer.user,
          customer_name: reservation_customer.customer.name,
          booking_time: reservation.booking_time,
          booking_customer_popup_url: Rails.application.routes.url_helpers.lines_user_bot_customers_url(
            business_owner_id: reservation_customer.customer.user_id,
            reservation_id: reservation_customer.reservation_id,
            customer_id: reservation_customer.customer_id,
            target_view: Customer::DASHBOARD_TARGET_VIEWS[:reservations],
            encrypted_user_id: MessageEncryptor.encrypt(reservation_customer.customer.user_id)
          )
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

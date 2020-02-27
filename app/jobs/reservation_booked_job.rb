class ReservationBookedJob < ApplicationJob
  queue_as :default

  def perform(reservation, customer)
    email = customer.with_google_contact.primary_email&.value&.address

    if email.present?
      CustomerMailer.with(reservation: reservation, customer: customer, email: email).reservation_confirmation.deliver_now
    end

    phone_number = customer.with_google_contact.primary_phone&.value

    if phone_number.present?
      Reservations::Notifications::SendCustomerSms.run!(
        phone_number: phone_number,
        customer: customer,
        reservation: reservation
      )
    end
  end
end

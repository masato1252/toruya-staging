class ReservationBookedJob < ApplicationJob
  queue_as :default

  def perform(reservation, customer)
    email = customer.with_google_contact.primary_email&.value&.address

    ReservationMailer.with(reservation: reservation, customer: customer, email: email).booked.deliver_now if email

    phone_number = customer.with_google_contact.primary_phone&.value

    if phone_number
      Booking::Notifications::SendCustomerSms.run!(
        phone_number: phone_number,
        customer: customer,
        reservation: reservation
      )
    end
  end
end

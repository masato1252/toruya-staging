class ReservationBookedJob < ApplicationJob
  queue_as :default

  def perform(reservation, customer)
    email = customer.with_google_contact.primary_email&.value&.address

    if email.present?
      CustomerMailer.with(reservation: reservation, customer: customer, email: email).reservation_confirmation.deliver_now
    end

    phone_number = customer.with_google_contact.primary_phone&.value

    if phone_number.present?
      shop = reservation.shop
      message = I18n.t(
        "reservation.notifications.sms",
        customer_name: customer.name,
        shop_name: shop.display_name,
        shop_phone_number: shop.phone_number,
        booking_time: "#{I18n.l(reservation.start_time, format: :long_date_with_wday)} ~ #{I18n.l(reservation.end_time, format: :time_only)}"
      )

      Reservations::Notifications::SendCustomerSms.run!(
        phone_number: phone_number,
        customer: customer,
        reservation: reservation,
        message: message
      )
    end
  end
end

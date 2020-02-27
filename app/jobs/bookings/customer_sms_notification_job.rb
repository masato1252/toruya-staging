module Bookings
  class CustomerSmsNotificationJob < ApplicationJob
    queue_as :default

    def perform(customer, reservation, phone_number)
      shop = reservation.shop
      message = I18n.t(
        "booking_page.notifications.sms",
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

class ReservationReminderJob < ApplicationJob
  queue_as :default

  def perform(reservation)
    reservation.customers.where(reminder_permission: true).each do |customer|
      email = customer.with_google_contact.primary_email&.value&.address

      if email.present?
        CustomerMailer.with(reservation: reservation, customer: customer, email: email).reservation_reminder.deliver_now
      end

      phone_number = customer.with_google_contact.primary_phone&.value

      if phone_number.present?
        shop = reservation.shop

        message = I18n.t(
          "customer.notifications.sms.reminder",
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
end

class ReservationReminderJob < ApplicationJob
  queue_as :default

  def perform(reservation)
    reservation.customers.where(reminder_permission: true).each do |customer|
      if customer.email_address.present?
        CustomerMailer.with(reservation: reservation, customer: customer, email: customer.email_address).reservation_reminder.deliver_now
      end

      if customer.phone_number.present? && customer.user.subscription.charge_required
        Reservations::Notifications::SendCustomerSms.run!(
          phone_number: customer.phone_number,
          customer: customer,
          reservation: reservation,
          message: reservation.reservation_customers.find_by(customer: customer).sms_reminder_message
        )
      end


      if customer.social_customers.exists?
        Reservations::Notifications::SocialMessage.run!(
          customer: customer,
          reservation: reservation,
          message: reservation.reservation_customers.find_by(customer: customer).sms_reminder_message
        )
      end
    end
  end
end

module CustomMessages
  module Customers
    class Base < ActiveInteraction::Base
      validate :validate_after_days
      validate :validate_before_minutes

      private

      def notify_service_customers(message)
        case message.after_days
        when nil, 0
          # For customers purchased/booked, so do nothing when this custom message was created
        else
          message.service.customers.find_each do |customer|
            ::CustomMessages::Customers::Next.perform_later(
              custom_message: message,
              receiver: customer,
              schedule_right_away: true
            )
          end
        end
      end

      def notify_reservation_customers(message)
        notify_before_minutes_reservation_customers(message)
        notify_after_days_reservation_customers(message)
      end

      def notify_before_minutes_reservation_customers(message)
        ReservationCustomer.
          includes(:reservation).
          where(booking_page: message.service).
          where("reservations.start_time > ?", Time.current).
          references(:reservation).each do |reservation_customer|
            reservation = reservation_customer.reservation

            if reservation.notifiable? && message.before_minutes
              Notifiers::Customers::CustomMessages::ReservationReminder.perform_at(
                schedule_at: reservation.start_time.advance(minutes: -message.before_minutes),
                custom_message: message,
                reservation: reservation,
                receiver: reservation_customer.customer
              )
            end
          end
      end

      def notify_after_days_reservation_customers(message)
        ReservationCustomer.
          includes(:reservation).
          where(booking_page: message.service).
          where("reservations.start_time > ?", Time.current).
          references(:reservation).each do |reservation_customer|
            reservation = reservation_customer.reservation

            if reservation.notifiable? && message.after_days
              Notifiers::Customers::CustomMessages::ReservationReminder.perform_at(
                schedule_at: reservation.start_time.advance(days: message.after_days),
                custom_message: message,
                reservation: reservation,
                receiver: reservation_customer.customer
              )
            end
          end
      end

      def validate_after_days
        if after_days.present? && after_days < 0
          errors.add(:after_days, :need_to_be_positive)
        end
      end

      def validate_before_minutes
        if before_minutes.present? && before_minutes <= 0
          errors.add(:before_minutes, :need_to_be_positive)
        end
      end
    end
  end
end

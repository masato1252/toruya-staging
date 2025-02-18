# frozen_string_literal: true

# Notify user, customer canceled a reservation
module Notifiers
  module Users
    module Reservations
      class CustomerCancel < Base
        deliver_by_priority [:line, :sms, :email]

        string :customer_name
        string :booking_customer_popup_url
        string :booking_time
        def message
          I18n.t("notifier.customer_cancel_reservation.message",
                 user_name: receiver.name,
                 customer_name: customer_name,
                 booking_time: booking_time,
                 booking_customer_popup_url: booking_customer_popup_url
                )
        end
      end
    end
  end
end

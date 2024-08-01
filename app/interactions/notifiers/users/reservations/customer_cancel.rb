# frozen_string_literal: true

# Notify user, customer canceled a reservation
module Notifiers
  module Users
    module Reservations
      class CustomerCancel < Base
        deliver_by :line

        string :customer_name
        string :booking_info_url

        def message
          I18n.t("notifier.customer_cancel_reservation.message",
                 user_name: receiver.name,
                 customer_name: customer_name,
                 booking_info_url: booking_info_url
                )
        end
      end
    end
  end
end

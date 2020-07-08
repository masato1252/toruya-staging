module Reservations
  module Notifications
    class Sms < ActiveInteraction::Base
      string :phone_number
      object :customer
      object :reservation
      string :message

      def execute
        compose(
          Sms::Create,
          user: customer.user,
          message: "#{message}#{I18n.t("customer.notifications.noreply")}",
          phone_number: phone_number,
          reservation: reservation,
          customer: customer
        )
      end
    end
  end
end

require "line_client"

module Reservations
  module Notifications
    class SocialMessage < ActiveInteraction::Base
      object :social_customer
      object :customer
      object :reservation
      string :message

      def execute
        LineClient.send(social_customer, message)

        Notification.create!(
          user: customer.user,
          customer_id: customer.id,
          reservation_id: reservation.id,
          content: message
        )
      end

      private

      def 

      def shop
        @shop ||= reservation.shop
      end
    end
  end
end

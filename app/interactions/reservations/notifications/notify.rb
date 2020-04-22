module Reservations
  module Notifications
    class Notify < ActiveInteraction::Base
      object :customer
      object :reservation
      string :phone_number, default: nil

      def execute
        if phone.present? && customer.user.subscription.charge_required
          Reservations::Notifications::Sms.run!(
            phone_number: phone,
            customer: customer,
            reservation: reservation,
            message: message
          )
        end


        if customer.social_customers.exists?
          customer.social_customers.each do |social_customer|
            Reservations::Notifications::SocialMessage.run!(
              customer: customer,
              social_customer: social_customer,
              reservation: reservation,
              message: message
            )
          end
        end
      end

      private

      def shop
        @shop ||= reservation.shop
      end

      def message
        raise NotImplementedError, "Subclass must implement this method"
      end

      def phone
        @phone ||= phone_number.presence || customer.phone_number
      end
    end
  end
end

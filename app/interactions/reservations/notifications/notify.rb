# frozen_string_literal: true

module Reservations
  module Notifications
    class Notify < ActiveInteraction::Base
      object :customer
      object :reservation
      string :phone_number, default: nil

      def execute
        if customer.social_customer
          compose(
            Reservations::Notifications::SocialMessage,
            social_customer: customer.social_customer,
            message: message
          )
        elsif phone.present? && customer.user.subscription.charge_required
          Reservations::Notifications::Sms.run!(
            phone_number: phone,
            customer: customer,
            reservation: reservation,
            message: message
          )
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
        @phone ||= phone_number.presence || customer.mobile_phone_number
      end
    end
  end
end

# frozen_string_literal: true

# Notify customer
module Reservations
  module Notifications
    class Notify < ActiveInteraction::Base
      # Include shared notification fallback logic
      include NotificationFallbackable

      object :customer
      object :reservation
      string :phone_number, default: nil
      string :email, default: nil

      def execute
        I18n.with_locale(customer.locale) do
          return unless business_owner.subscription.active?

          send_notification_with_fallbacks(preferred_channel: business_owner.customer_notification_channel)
        end
      end

      def shop
        @shop ||= reservation.shop
      end

      def message
        raise NotImplementedError, "Subclass must implement this method"
      end

      def mail
        @mail ||= email.presence || customer.email
      end

      def phone
        @phone ||= phone_number.presence || customer.mobile_phone_number
      end

      def business_owner
        @business_owner ||= customer.user
      end

      # Methods required by NotificationFallbackable
      # These are kept here as they have custom implementations

      def available_to_send_sms?
        phone.present?
      end

      def available_to_send_line?
        customer.social_customer && customer.user.social_account.line_settings_finished?
      end

      def available_to_send_email?
        mail.present?
      end

      def notify_by_email
        compose(
          SocialMessages::CreateEmail,
          customer: customer,
          email: mail,
          message: message,
          subject: I18n.t("customer_mailer.custom.title", company_name: business_owner.profile.company_name),
          reservation: reservation
        )
      end

      def notify_by_sms
        compose(
          Reservations::Notifications::Sms,
          phone_number: phone,
          customer: customer,
          reservation: reservation,
          message: "#{message}#{I18n.t("customer.notifications.noreply")}"
        )
      end

      def notify_by_line
        compose(
          Reservations::Notifications::SocialMessage,
          social_customer: customer.social_customer,
          message: message
        )
      end
    end
  end
end
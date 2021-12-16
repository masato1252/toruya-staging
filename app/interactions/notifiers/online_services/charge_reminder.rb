# frozen_string_literal: true

module Notifiers
  module OnlineServices
    class ChargeReminder < Base
      deliver_by :line

      object :online_service_customer_relation
      object :online_service_customer_price, class: OnlineServiceCustomerPrice

      validate :receiver_should_be_customer

      def message
        I18n.t(
          "notifier.online_service.charge_reminder.message",
          customer_name: receiver.display_last_name,
          service_title: online_service.name,
          charge_date: I18n.l(online_service_customer_price.charge_at.to_date, format: :year_month_date),
          shop_name: online_service.company.company_name,
          shop_phone: online_service.company.phone_number,
          customer_status_online_service_url: url_helpers.customer_status_online_service_url(
            slug: online_service_customer_relation.online_service.slug,
            encrypted_social_service_user_id: MessageEncryptor.encrypt(online_service_customer_relation.customer.social_customer.social_user_id)
          )
        )
      end

      private

      def online_service
        online_service_customer_relation.online_service
      end
    end
  end
end

# frozen_string_literal: true

module Reservations
  module Notifications
    class Confirmation < Notify
  def execute
    I18n.with_locale(customer.locale) do
      Rails.logger.info "[Confirmation] ===== 予約確定通知実行 ====="
      Rails.logger.info "[Confirmation] reservation_id: #{reservation.id}, customer_id: #{customer.id}"
      Rails.logger.info "[Confirmation] start_time: #{reservation.start_time}, current: #{Time.current}"
      
      if reservation.start_time < Time.current
        Rails.logger.info "[Confirmation] ⚠️ 過去の予約のためスキップ"
        return
      end

      Rails.logger.info "[Confirmation] ✅ 予約確定通知送信開始"
      super
    end
  end

      private

      def message
        reservation_customer = ReservationCustomer.where(reservation: reservation, customer: customer).first
        template = if reservation_customer.booking_page.present? && !reservation_customer.booking_page.use_shop_default_message
          compose(
            ::CustomMessages::Customers::Template,
            product: reservation_customer.booking_page,
            scenario: ::CustomMessages::Customers::Template::RESERVATION_CONFIRMED,
            custom_message_only: true
          )
        end

        template ||= compose(
          ::CustomMessages::Customers::Template,
          product: reservation.shop,
          scenario: ::CustomMessages::Customers::Template::RESERVATION_CONFIRMED
        )

        Translator.perform(template, reservation.message_template_variables(customer))
      end
    end
  end
end

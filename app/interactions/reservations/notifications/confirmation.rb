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

      # 予約確定通知のCustomMessageを取得（重複チェック用）
      def custom_message_for_tracking
        @custom_message_for_tracking ||= begin
          reservation_customer = ReservationCustomer.find_by(customer: customer, reservation: reservation)
          return nil unless reservation_customer

          # booking_pageがあり、カスタムメッセージを使う場合
          if reservation_customer.booking_page.present? && !reservation_customer.booking_page.use_shop_default_message
            CustomMessage.find_by(
              service_type: "BookingPage",
              service_id: reservation_customer.booking_page.id,
              scenario: ::CustomMessages::Customers::Template::RESERVATION_CONFIRMED,
              after_days: nil
            )
          end || CustomMessage.find_by(
            service_type: "Shop",
            service_id: reservation.shop.id,
            scenario: ::CustomMessages::Customers::Template::RESERVATION_CONFIRMED,
            after_days: nil
          )
        end
      end
    end
  end
end

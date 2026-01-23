# frozen_string_literal: true

require "translator"

# pending notification to customer
module Reservations
  module Notifications
    class Booking < Notify
      object :booking_page
      array :booking_options

  def execute
    I18n.with_locale(customer.locale) do
      Rails.logger.info "[Booking] ===== 仮予約確定通知実行 ====="
      Rails.logger.info "[Booking] reservation_id: #{reservation.id}, customer_id: #{customer.id}"
      Rails.logger.info "[Booking] booking_page_id: #{booking_page.id}"
      Rails.logger.info "[Booking] ✅ 仮予約確定通知送信開始"
      super
    end
  end

      private

      def message
        template =
          if booking_page.use_shop_default_message
            compose(
              ::CustomMessages::Customers::Template,
              product: booking_page.shop,
              scenario: ::CustomMessages::Customers::Template::BOOKING_PAGE_BOOKED
            )
          end

        template = compose(
          ::CustomMessages::Customers::Template,
          product: booking_page,
          scenario: ::CustomMessages::Customers::Template::BOOKING_PAGE_BOOKED,
          custom_message_only: true
        ) if template.blank?

        template = compose(
          ::CustomMessages::Customers::Template,
          product: booking_page.shop,
          scenario: ::CustomMessages::Customers::Template::BOOKING_PAGE_BOOKED
        ) unless template.present?

        Translator.perform(template, reservation.message_template_variables(customer))
      end
    end
  end
end

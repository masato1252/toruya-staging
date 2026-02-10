# frozen_string_literal: true

# reservation reminder to customer
module Reservations
  module Notifications
    class Reminder < Notify
  def execute
    I18n.with_locale(customer.locale) do
      Rails.logger.info "[Reminder] ===== 24時間前リマインド実行 ====="
      Rails.logger.info "[Reminder] reservation_id: #{reservation.id}, customer_id: #{customer.id}"
      Rails.logger.info "[Reminder] remind_customer?: #{reservation.remind_customer?(customer)}"
      
      # 重複送信チェック：過去2時間以内に同じリマインダーが送信されていないか確認
      # custom_message_idも条件に含める
      cm_for_tracking = custom_message_for_tracking
      already_sent = ::SocialMessage.where(
        customer_id: customer.id,
        user_id: reservation.user_id,
        channel: 'email',
        reservation_id: reservation.id,
        custom_message_id: cm_for_tracking&.id  # custom_message_idで絞り込み（nilも含む）
      ).where("created_at >= ?", Time.current - 2.hours)
       .exists?

      if already_sent
        Rails.logger.info "[Reminder] ⚠️ 過去2時間以内に送信済みのためスキップ (custom_message_id: #{cm_for_tracking&.id})"
        return
      end
      
      unless reservation.remind_customer?(customer)
        Rails.logger.info "[Reminder] ⚠️ remind_customer? が false のためスキップ"
        return
      end

      Rails.logger.info "[Reminder] ✅ リマインド送信開始 (custom_message_id: #{cm_for_tracking&.id})"
      super
    end
  end

      private

      def message
        @message ||= begin
          reservation_customer = ReservationCustomer.find_by!(customer: customer, reservation: reservation)
          booking_page = reservation_customer.booking_page
          activity = reservation_customer.survey_activity

          if booking_page
            # Determine which message to use based on the setting
            template =
              if booking_page.use_shop_default_message
                # Use shop default message
                compose(
                  ::CustomMessages::Customers::Template,
                  product: reservation.shop,
                  scenario: ::CustomMessages::Customers::Template::RESERVATION_ONE_DAY_REMINDER
                )
              end

            # Use booking page custom message
            template ||= compose(
              ::CustomMessages::Customers::Template,
              product: booking_page,
              scenario: ::CustomMessages::Customers::Template::BOOKING_PAGE_ONE_DAY_REMINDER,
              custom_message_only: true
            )
          end

          if activity
            template ||= compose(
              ::CustomMessages::Customers::Template,
              product: activity.survey,
              scenario: ::CustomMessages::Customers::Template::ACTIVITY_ONE_DAY_REMINDER
            )
          end

          # Only use shop default message as fallback when no template is set above
          template ||= compose(
            ::CustomMessages::Customers::Template,
            product: reservation.shop,
            scenario: ::CustomMessages::Customers::Template::RESERVATION_ONE_DAY_REMINDER
          )

          Translator.perform(template, reservation.message_template_variables(customer))
        end
      end

      # 24時間前リマインドのCustomMessageを取得（重複チェック用）
      def custom_message_for_tracking
        @custom_message_for_tracking ||= begin
          reservation_customer = ReservationCustomer.find_by(customer: customer, reservation: reservation)
          return nil unless reservation_customer

          booking_page = reservation_customer.booking_page
          activity = reservation_customer.survey_activity

          # booking_pageがあり、shop default messageを使う場合
          if booking_page&.use_shop_default_message
            CustomMessage.find_by(
              service_type: "Shop",
              service_id: reservation.shop.id,
              scenario: ::CustomMessages::Customers::Template::RESERVATION_ONE_DAY_REMINDER,
              after_days: nil
            )
          # booking_pageがあり、カスタムメッセージを使う場合
          elsif booking_page
            CustomMessage.find_by(
              service_type: "BookingPage",
              service_id: booking_page.id,
              scenario: ::CustomMessages::Customers::Template::BOOKING_PAGE_ONE_DAY_REMINDER,
              after_days: nil
            ) || CustomMessage.find_by(
              service_type: "Shop",
              service_id: reservation.shop.id,
              scenario: ::CustomMessages::Customers::Template::RESERVATION_ONE_DAY_REMINDER,
              after_days: nil
            )
          # activityがある場合
          elsif activity
            CustomMessage.find_by(
              service_type: "Survey",
              service_id: activity.survey.id,
              scenario: ::CustomMessages::Customers::Template::ACTIVITY_ONE_DAY_REMINDER,
              after_days: nil
            )
          # デフォルト：shopのメッセージ
          else
            CustomMessage.find_by(
              service_type: "Shop",
              service_id: reservation.shop.id,
              scenario: ::CustomMessages::Customers::Template::RESERVATION_ONE_DAY_REMINDER,
              after_days: nil
            )
          end
        end
      end
    end
  end
end

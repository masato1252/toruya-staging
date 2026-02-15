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

          preferred_channel = determine_customer_notification_channel
          send_notification_with_fallbacks(preferred_channel: preferred_channel)

          # LINE通知リクエストで送信した場合、最終通知かチェックして店舗へ即時通知
          # 試用期間中は通常のLINE通知なので、LINE通知リクエスト完了チェックは不要
          if preferred_channel == "line" && business_owner.subscription.in_free_plan? && !business_owner.subscription.in_trial?
            approved_request = LineNoticeRequest.approved
              .where(reservation_id: reservation.id)
              .first

            if approved_request.present? && !reservation.has_future_notifications_for?(customer)
              Rails.logger.info "[LineNoticeCompleted] 最終通知検出(Notify経由): reservation_id=#{reservation.id}, customer=#{customer.id} → 店舗へ即時通知"
              Notifiers::Users::LineNoticeCompleted.run(
                receiver: business_owner,
                line_notice_request: approved_request,
                customer: customer
              )
            end
          end
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
          reservation: reservation,
          custom_message: custom_message_for_tracking
        )
      end

      # メッセージの種類を識別するためのCustomMessageオブジェクト
      # サブクラスでオーバーライドして適切なCustomMessageを返す
      def custom_message_for_tracking
        nil
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

      # 顧客への通知チャンネルを決定
      # 試用期間中は有料プランと同様に店舗設定に従う
      # 無料プラン（試用期間外）でも、予約に関するLINE通知リクエストが承認されていればLINEで送信
      def determine_customer_notification_channel
        # 無料プランかつ試用期間外の場合のみ、LINE通知リクエストベースの判定
        if business_owner.subscription.in_free_plan? && !business_owner.subscription.in_trial?
          # LINE通知リクエストが承認済みか確認
          approved_request = LineNoticeRequest.approved
            .where(reservation_id: reservation.id)
            .first
          
          # 承認済みならLINE、そうでなければemail
          return approved_request.present? ? "line" : "email"
        end
        
        # 有料プランまたは試用期間中は店舗の設定に従う
        business_owner.customer_notification_channel
      end
    end
  end
end
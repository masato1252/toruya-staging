# frozen_string_literal: true

require "sms_client"

module Sms
  class Create < ActiveInteraction::Base
    string :phone_number
    string :message
    object :user, default: nil
    object :customer, default: nil
    object :reservation, default: nil

    def execute
      # メッセージにLINE通知リクエスト案内を追加（メールと同じ条件）
      final_message = append_line_notice_request_info(message)
      
      SmsClient.send(phone_number, final_message, user&.locale || customer&.locale || "ja")

      if customer
        SocialMessage.create!(
          social_account: customer.social_customer&.social_account,
          social_customer: customer.social_customer,
          customer_id: customer.id,
          user_id: customer.user_id,
          raw_content: final_message,
          content_type: "text",
          readed_at: Time.current,
          sent_at: Time.current,
          message_type: "bot",
          channel: SocialMessage.channels[:sms]
        )
      end

      Notification.create!(
        user: user,
        phone_number: phone_number,
        content: final_message,
        customer_id: customer&.id,
        reservation_id: reservation&.id
      )
    rescue Twilio::REST::RestError => e
      Rollbar.error(
        e,
        phone_numbers: phone_number,
        user_id: user&.id,
        customer_id: customer&.id,
        reservation_id: reservation&.id,
        rails_env: Rails.configuration.x.env
      )
    end

    private

    def append_line_notice_request_info(original_message)
      # 予約がない、または無料プランでない、またはLINE連携未完了の場合は追加しない
      return original_message unless should_show_line_notice_request_info?

      # 既にリクエスト済みかどうかを確認
      existing_request = LineNoticeRequest.pending.find_by(reservation_id: reservation.id)

      if existing_request
        # リクエスト済みの場合
        append_pending_request_notice(original_message)
      else
        # 未リクエストの場合
        append_request_invitation(original_message)
      end
    end

    def should_show_line_notice_request_info?
      return false unless reservation.present?
      return false unless customer.present?
      return false unless customer.user.subscription.current_plan.free_level?
      return false unless customer.user.social_account&.line_settings_verified?
      
      true
    end

    def append_request_invitation(original_message)
      request_url = Rails.application.routes.url_helpers.line_notice_requests_url(
        reservation_id: reservation.id,
        host: ENV['APP_HOST'] || 'toruya.com',
        protocol: 'https'
      )

      separator = "\n\n--------------------\n"
      notice_text = I18n.t('customer_mailer.line_notice_request.sms.invitation_text', request_url: request_url)
      [original_message, separator, notice_text].join
    end

    def append_pending_request_notice(original_message)
      separator = "\n\n--------------------\n"
      notice_text = I18n.t('customer_mailer.line_notice_request.sms.pending_approval_text')
      [original_message, separator, notice_text].join
    end
  end
end

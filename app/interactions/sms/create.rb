# frozen_string_literal: true

require "sms_client"
require "message_encryptor"

module Sms
  class Create < ActiveInteraction::Base
    string :phone_number
    string :message
    object :user, default: nil
    object :customer, default: nil
    object :reservation, default: nil

    def execute
      # メッセージにLINE通知リクエスト案内または連携のススメを追加（メールと同じ条件）
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
      # 予約がない、顧客がいない、またはLINE連携未完了の場合は追加しない
      return original_message unless reservation.present?
      return original_message unless customer.present?
      return original_message unless customer.user.social_account&.line_settings_verified?

      # マインドマップに基づく条件分岐
      if should_show_line_request_notice?
        # 既にリクエスト済みかどうかを確認
        existing_request = LineNoticeRequest.pending.find_by(reservation_id: reservation.id)

        if existing_request
          append_pending_request_notice(original_message)
        else
          append_request_invitation(original_message)
        end
      elsif should_show_line_recommendation?
        append_line_recommendation(original_message)
      else
        original_message
      end
    end

    def should_show_line_request_notice?
      # 無料プラン（試用期間外）の場合のみ
      customer.user.subscription.in_free_plan? && !customer.user.trial_member?
    end

    def should_show_line_recommendation?
      # 顧客LINE連携なし + (有料プラン or 試用期間中)
      customer.social_customer.nil? && (!customer.user.subscription.in_free_plan? || customer.user.trial_member?)
    end

    def append_request_invitation(original_message)
      request_url = Rails.application.routes.url_helpers.line_notice_requests_url(
        reservation_id: reservation.id,
        host: ENV['APP_HOST'] || 'toruya.com',
        protocol: 'https'
      )

      separator = "\n\n--------------------\n"
      notice_text = I18n.t('customer_mailer.line_notice_request.sms_invitation_text', request_url: request_url)
      [original_message, separator, notice_text].join
    end

    def append_pending_request_notice(original_message)
      separator = "\n\n--------------------\n"
      notice_text = I18n.t('customer_mailer.line_notice_request.sms_pending_approval_text')
      [original_message, separator, notice_text].join
    end

    def append_line_recommendation(original_message)
      line_connect_url = build_line_connect_url
      return original_message unless line_connect_url

      separator = "\n\n--------------------\n"
      notice_text = I18n.t('customer_mailer.line_notice_request.sms_line_recommendation_text', line_connect_url: line_connect_url)
      [original_message, separator, notice_text].join
    end

    def build_line_connect_url
      social_account = customer.user.social_account
      return nil unless social_account&.is_login_available?

      encrypted_id = MessageEncryptor.encrypt(social_account.id)
      # LINE連携後のリダイレクト先（予約詳細ページ）
      redirect_url = Rails.application.routes.url_helpers.shop_reservation_url(
        customer.user.shop, reservation,
        host: ENV['APP_HOST'] || 'toruya.com',
        protocol: 'https'
      )

      Rails.application.routes.url_helpers.user_line_omniauth_authorize_url(
        host: ENV['APP_HOST'] || 'toruya.com',
        protocol: 'https',
        oauth_social_account_id: encrypted_id,
        oauth_redirect_to_url: redirect_url,
        customer_id: customer.id,
        prompt: 'consent',
        bot_prompt: 'aggressive'
      )
    end
  end
end

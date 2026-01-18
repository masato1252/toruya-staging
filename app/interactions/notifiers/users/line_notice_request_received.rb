# frozen_string_literal: true

module Notifiers
  module Users
    class LineNoticeRequestReceived < Base
      object :line_notice_request

      def execute
        # 店舗オーナーのLINE通知設定が完了しているか確認
        return unless available_to_send_line?

        notify_by_line
      end

      def message
        reservation = line_notice_request.reservation
        customer = line_notice_request.customer
        
        I18n.with_locale(receiver.locale) do
          <<~MESSAGE.strip
            【LINE通知リクエスト】

            お客様からLINE通知のリクエストが届きました。

            ■ 予約情報
            お客様名: #{customer.name}
            予約日時: #{I18n.l(reservation.start_time, format: :long)}
            メニュー: #{reservation.menus_sentence}

            以下のリンクから内容を確認できます。
            #{approval_url}
          MESSAGE
        end
      end

      private

      def approval_url
        Rails.application.routes.url_helpers.lines_user_bot_line_notice_request_url(
          business_owner_id: receiver.id,
          id: line_notice_request.id,
          host: ENV['HOST'] || 'toruya.com',
          protocol: 'https'
        )
      end

      def available_to_send_line?
        receiver.social_account&.line_settings_verified? && receiver.social_user&.social_user_id.present?
      end

      def notify_by_line
        LineClient.push_message(
          receiver.social_user,
          message
        )
      end

      def target_line_user
        receiver.social_user
      end

      def target_email_user
        receiver
      end
    end
  end
end


# frozen_string_literal: true

module Notifiers
  module Users
    class LineNoticeCompleted < Base
      object :line_notice_request
      object :customer

      def execute
        # 店舗オーナーのLINE通知設定が完了しているか確認
        return unless available_to_send_line?

        notify_by_line
      end

      def message
        reservation = line_notice_request.reservation
        
        I18n.with_locale(receiver.locale) do
          <<~MESSAGE.strip
            #{customer.family_name}様へのLINEによるお知らせ送信が全て完了いたしました。
            以降もLINEによるお知らせ送信をご利用いただくには、有料プランの契約が必要です。

            ＜有料プランを確認する＞
            #{plans_url}
          MESSAGE
        end
      end

      private

      def plans_url
        Rails.application.routes.url_helpers.lines_user_bot_settings_plans_url(
          business_owner_id: receiver.id,
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


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
        customer_family_name = customer.last_name || customer.name&.split(' ')&.first || customer.name || '（氏名不明）'
        
        I18n.with_locale(receiver.locale) do
          <<~MESSAGE.strip
            #{customer_family_name}様へのLINEによるお知らせ送信が全て完了いたしました。
            以降もLINEによるお知らせ送信をご利用いただくには、有料プランの契約が必要です。

            ＜有料プランを確認する＞
            #{plans_url}
          MESSAGE
        end
      end

      private

      def plans_url
        Rails.application.routes.url_helpers.lines_user_bot_settings_plans_url(
          business_owner_id: receiver.id
        )
      end

      def available_to_send_line?
        receiver.social_account&.line_settings_verified? && receiver.social_user&.social_user_id.present?
      end

      def notify_by_line
        # LineClient.sendに統一（他のNotifierと同じパターン）
        social_user = receiver.social_user
        
        unless social_user&.social_user_id.present?
          Rails.logger.warn("[LineNoticeCompleted] ⚠️ receiver.social_user が存在しません (user_id=#{receiver.id})")
          return
        end
        
        Rails.logger.info("[LineNoticeCompleted] 店舗オーナーにLINE通知送信: social_user_id=#{social_user.social_user_id}, user_id=#{receiver.id}")
        
        begin
          LineClient.send(social_user, message)
        rescue => e
          Rails.logger.error("[LineNoticeCompleted] ❌ LINE送信失敗: #{e.class} - #{e.message}")
          Rollbar.error(e, social_user_id: social_user.social_user_id, user_id: receiver.id, line_notice_request_id: line_notice_request.id)
        end
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


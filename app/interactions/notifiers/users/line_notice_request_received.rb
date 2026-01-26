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
        customer_family_name = customer.last_name || customer.name&.split(' ')&.first || customer.name || '（氏名不明）'
        reservation_day = I18n.l(reservation.start_time.to_date, format: :long)
        is_free_trial = receiver.line_notice_free_trial_available?
        
        I18n.with_locale(receiver.locale) do
          if is_free_trial
            # 初回（無料）の文言
            <<~MESSAGE.strip
              予約客 #{customer_family_name}様より、LINEでのお知らせ受信リクエストが届いています。

              LINEでリマインド等のメッセージを自動送信するには、有料プランの契約が必要です。

              ✅仮予約作成のお知らせ
              ✅予約確定のお知らせ
              ✅24時間前のリマインド
              ✅カスタム作成した全てのリマインド

              特別に、今回 #{reservation_day} のご予約に限り、#{customer_family_name}様のLINEにお知らせ送信を、無料でお試しいただけます。

              ＜LINEでお知らせを試す＞
              #{approval_url}
            MESSAGE
          else
            # 二回目以降（都度課金）の文言
            <<~MESSAGE.strip
              予約客 #{customer_family_name}様より、LINEでのお知らせ受信リクエストが届いています。

              LINEでリマインド等のメッセージを自動送信するには、有料プランの契約が必要です。

              ✅仮予約作成のお知らせ
              ✅予約確定のお知らせ
              ✅24時間前のリマインド
              ✅カスタム作成した全てのリマインド

              今回 #{reservation_day} のご予約に限り、#{customer_family_name}様のLINEにお知らせ送信を、250円＋税でお試しいただけます。

              ＜LINEでお知らせを試す＞
              #{approval_url}

              また、有料プランにご契約いただくことで、すべての予約でLINEでお知らせを自動送信できます。

              ＜有料プランを確認する＞
              #{plans_url}
            MESSAGE
          end
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

      def plans_url
        Rails.application.routes.url_helpers.lines_user_bot_settings_plans_url(
          business_owner_id: receiver.id,
          host: ENV['HOST'] || 'toruya.com',
          protocol: 'https',
          anchor: 'plans-menu-item'
        )
      end

      def available_to_send_line?
        receiver.social_account&.line_settings_verified? && receiver.social_user&.social_user_id.present?
      end

      def notify_by_line
        # receiverはUser（店舗オーナー）、receiver.social_userはToruya公式アカウントのSocialUser
        social_user = receiver.social_user
        
        unless social_user&.social_user_id.present?
          Rails.logger.warn("[LineNoticeRequestReceived] ⚠️ receiver.social_user が存在しません (user_id=#{receiver.id})")
          return
        end
        
        Rails.logger.info("[LineNoticeRequestReceived] 店舗オーナーにLINE通知送信: social_user_id=#{social_user.social_user_id}, user_id=#{receiver.id}")
        
        begin
          # SocialUserはclientとsocial_user_idを持つので、LineClient.sendに直接渡せる
          LineClient.send(social_user, message)
        rescue => e
          Rails.logger.error("[LineNoticeRequestReceived] ❌ LINE送信失敗: #{e.class} - #{e.message}")
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


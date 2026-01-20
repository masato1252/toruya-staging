# frozen_string_literal: true

module LineNoticeRequests
  class Approve < ActiveInteraction::Base
    object :line_notice_request
    object :user
    boolean :is_free_trial
    string :payment_method_id, default: nil
    string :setup_intent_id, default: nil
    string :payment_intent_id, default: nil

    def execute
      # バリデーション
      unless line_notice_request.can_be_approved?
        errors.add(:line_notice_request, :cannot_be_approved)
        return
      end

      ActiveRecord::Base.transaction do
        if is_free_trial
          # 無料トライアル
          charge = LineNoticeCharge.create_free_trial!(
            user: user,
            reservation: line_notice_request.reservation,
            line_notice_request: line_notice_request
          )
        else
          # 有料決済
          charge = process_paid_charge
          return unless charge
        end

        # リクエストを承認済みに更新
        line_notice_request.approve!

        # 承認完了をユーザーに通知（オプション: 後で実装可能）
        # Notifiers::Customers::LineNoticeRequestApproved.perform_later(
        #   receiver: line_notice_request.customer,
        #   line_notice_request: line_notice_request
        # )

        charge
      end
    end

    private

    def process_paid_charge
      # Stripe顧客とPaymentMethodを準備（顧客IDがない場合は自動作成）
      # 3DS認証後のリトライの場合は、setup_intent_idを渡す
      store_customer_outcome = compose(
        Payments::StoreStripeCustomer,
        user: user,
        authorize_token: payment_method_id,
        setup_intent_id: setup_intent_id
      )
      
      unless store_customer_outcome.valid?
        # エラー詳細を取得
        user_error = store_customer_outcome.errors.details[:user]&.first || {}
        raw_stripe_message = user_error[:stripe_error_message]
        user_friendly_message = I18n.t("active_interaction.errors.models.line_notice_requests/approve.attributes.user.store_customer_failed")
        
        # エラーメッセージにはユーザー向けメッセージと生のStripeエラーを両方含める
        combined_error_message = if raw_stripe_message.present?
          "#{user_friendly_message} | Raw error: #{raw_stripe_message}"
        else
          "#{user_friendly_message} | Raw error: #{store_customer_outcome.errors.full_messages.join(', ')}"
        end
        
        create_failed_charge(error_message: combined_error_message)
        errors.merge!(store_customer_outcome.errors)
        return nil
      end

      # Stripe決済処理
      amount = Money.new(LineNoticeCharge::LINE_NOTICE_CHARGE_AMOUNT_JPY, user.currency || 'JPY')
      
      # Stripeカスタマー取得（上記で確実に作成されている）
      stripe_customer_id = user.subscription.reload.stripe_customer_id
      unless stripe_customer_id.present?
        user_friendly_message = I18n.t("active_interaction.errors.models.line_notice_requests/approve.attributes.user.no_stripe_customer")
        errors.add(:user, :no_stripe_customer, user_message: user_friendly_message)
        # Stripe顧客IDがない場合も失敗レコードを作成
        create_failed_charge(error_message: "#{user_friendly_message} | Raw error: Stripe customer not found after setup")
        return nil
      end

      begin
        # PaymentIntentを作成または取得
        payment_intent = if payment_intent_id.present?
          # 3DS認証後のリトライの場合は、既存のPaymentIntentを取得
          Stripe::PaymentIntent.retrieve(payment_intent_id)
        else
          # 新規PaymentIntentを作成
          Stripe::PaymentIntent.create({
            amount: amount.fractional * amount.currency.default_subunit_to_unit,
            currency: amount.currency.iso_code,
            customer: stripe_customer_id,
            payment_method: payment_method_id,
            description: "LINE通知リクエスト承認 - 予約ID: #{line_notice_request.reservation_id}",
            statement_descriptor: "Toruya LINE通知",
            metadata: {
              user_id: user.id,
              reservation_id: line_notice_request.reservation_id,
              line_notice_request_id: line_notice_request.id,
              type: 'line_notice_charge'
            },
            off_session: false,
            confirm: true,
            payment_method_types: ['card']
          })
        end

        case payment_intent.status
        when 'succeeded'
          # 決済成功 - Chargeレコード作成
          LineNoticeCharge.create_paid_charge!(
            user: user,
            reservation: line_notice_request.reservation,
            line_notice_request: line_notice_request,
            payment_intent_id: payment_intent.id,
            stripe_charge_details: payment_intent.as_json
          )
        when 'requires_action', 'requires_payment_method'
          user_friendly_message = I18n.t("active_interaction.errors.models.line_notice_requests/approve.attributes.payment.requires_action")
          # ユーザー向けメッセージと生のエラーを両方記録
          error_details = "Payment intent status: #{payment_intent.status}"
          error_details += ", last_payment_error: #{payment_intent.last_payment_error&.dig('message')}" if payment_intent.last_payment_error.present?
          
          errors.add(:payment, :requires_action, 
            client_secret: payment_intent.client_secret,
            payment_intent_id: payment_intent.id,
            user_message: user_friendly_message
          )
          # 追加アクション必要の場合も失敗レコードを作成
          create_failed_charge(
            error_message: "#{user_friendly_message} | Raw error: #{error_details}",
            payment_intent_id: payment_intent.id,
            stripe_charge_details: payment_intent.as_json
          )
          nil
        else
          user_friendly_message = I18n.t("active_interaction.errors.models.line_notice_requests/approve.attributes.payment.failed")
          # ユーザー向けメッセージと生のエラーを両方記録
          error_details = "Payment intent failed with status: #{payment_intent.status}"
          error_details += ", last_payment_error: #{payment_intent.last_payment_error&.dig('message')}" if payment_intent.last_payment_error.present?
          
          errors.add(:payment, :failed, user_message: user_friendly_message)
          # その他の失敗ケースも記録
          create_failed_charge(
            error_message: "#{user_friendly_message} | Raw error: #{error_details}",
            payment_intent_id: payment_intent.id,
            stripe_charge_details: payment_intent.as_json
          )
          
          if Rails.configuration.x.env.production?
            Rollbar.error("LINE notice charge payment failed", 
              status: payment_intent.status, 
              user_id: user.id,
              line_notice_request_id: line_notice_request.id
            )
          end
          nil
        end
      rescue Stripe::CardError => e
        stripe_error = e.json_body&.dig(:error) || {}
        raw_error_message = stripe_error[:message] || e.message
        user_friendly_message = I18n.t("active_interaction.errors.models.line_notice_requests/approve.attributes.payment.card_error")
        
        errors.add(:payment, :card_error, 
          stripe_error_code: stripe_error[:code],
          stripe_error_message: raw_error_message,
          user_message: user_friendly_message
        )
        # カードエラーも記録
        create_failed_charge(
          error_message: "#{user_friendly_message} | Raw error: #{raw_error_message} (code: #{stripe_error[:code]})",
          stripe_charge_details: { error: e.json_body }
        )
        
        if Rails.configuration.x.env.production?
          Rollbar.error(e, user_id: user.id, line_notice_request_id: line_notice_request.id, stripe_error: stripe_error)
        end
        nil
      rescue Stripe::StripeError => e
        stripe_error = e.json_body&.dig(:error) || {}
        raw_error_message = stripe_error[:message] || e.message
        user_friendly_message = I18n.t("active_interaction.errors.models.line_notice_requests/approve.attributes.payment.stripe_error")
        
        errors.add(:payment, :stripe_error, 
          stripe_error_code: stripe_error[:code],
          stripe_error_message: raw_error_message,
          user_message: user_friendly_message
        )
        # Stripeエラーも記録
        create_failed_charge(
          error_message: "#{user_friendly_message} | Raw error: #{raw_error_message} (code: #{stripe_error[:code]})",
          stripe_charge_details: { error: e.json_body }
        )
        
        if Rails.configuration.x.env.production?
          Rollbar.error(e, user_id: user.id, line_notice_request_id: line_notice_request.id, stripe_error: stripe_error)
        end
        nil
      end
    end

    def create_failed_charge(error_message:, payment_intent_id: nil, stripe_charge_details: nil)
      LineNoticeCharge.create!(
        user: user,
        reservation: line_notice_request.reservation,
        line_notice_request: line_notice_request,
        amount: LineNoticeCharge::LINE_NOTICE_CHARGE_AMOUNT_JPY,
        amount_currency: user.currency || 'JPY',
        charge_date: Date.current,
        is_free_trial: false,
        state: :failed,
        error_message: error_message,
        payment_intent_id: payment_intent_id,
        stripe_charge_details: stripe_charge_details
      )
    end
  end
end


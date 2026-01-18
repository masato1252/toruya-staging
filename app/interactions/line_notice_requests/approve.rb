# frozen_string_literal: true

module LineNoticeRequests
  class Approve < ActiveInteraction::Base
    object :line_notice_request
    object :user
    boolean :is_free_trial
    string :payment_method_id, default: nil

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
      store_customer_outcome = compose(
        Payments::StoreStripeCustomer,
        user: user,
        authorize_token: payment_method_id
      )
      
      unless store_customer_outcome.valid?
        errors.merge!(store_customer_outcome.errors)
        create_failed_charge(error_message: "Failed to setup Stripe customer: #{store_customer_outcome.errors.full_messages.join(', ')}")
        return nil
      end

      # Stripe決済処理
      amount = Money.new(LineNoticeCharge::LINE_NOTICE_CHARGE_AMOUNT_JPY, user.currency || 'JPY')
      
      # Stripeカスタマー取得（上記で確実に作成されている）
      stripe_customer_id = user.subscription.reload.stripe_customer_id
      unless stripe_customer_id.present?
        errors.add(:user, :no_stripe_customer)
        # Stripe顧客IDがない場合も失敗レコードを作成
        create_failed_charge(error_message: "Stripe customer not found after setup")
        return nil
      end

      begin
        # PaymentIntentを作成
        payment_intent = Stripe::PaymentIntent.create({
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
          errors.add(:payment, :requires_action)
          # 追加アクション必要の場合も失敗レコードを作成
          create_failed_charge(
            error_message: "Payment requires action: #{payment_intent.status}",
            payment_intent_id: payment_intent.id,
            stripe_charge_details: payment_intent.as_json
          )
          nil
        else
          errors.add(:payment, :failed)
          # その他の失敗ケースも記録
          create_failed_charge(
            error_message: "Payment failed with status: #{payment_intent.status}",
            payment_intent_id: payment_intent.id,
            stripe_charge_details: payment_intent.as_json
          )
          Rollbar.error("LINE notice charge payment failed", 
            status: payment_intent.status, 
            user_id: user.id,
            line_notice_request_id: line_notice_request.id
          )
          nil
        end
      rescue Stripe::CardError => e
        errors.add(:payment, :card_error, message: e.message)
        # カードエラーも記録
        create_failed_charge(
          error_message: "Card error: #{e.message}",
          stripe_charge_details: { error: e.json_body }
        )
        Rollbar.error(e, user_id: user.id, line_notice_request_id: line_notice_request.id)
        nil
      rescue Stripe::StripeError => e
        errors.add(:payment, :stripe_error, message: e.message)
        # Stripeエラーも記録
        create_failed_charge(
          error_message: "Stripe error: #{e.message}",
          stripe_charge_details: { error: e.json_body }
        )
        Rollbar.error(e, user_id: user.id, line_notice_request_id: line_notice_request.id)
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


# frozen_string_literal: true

require "order_id"

class Lines::UserBot::Settings::PaymentsController < Lines::UserBotDashboardController
  skip_before_action :authenticate_current_user!, only: [:receipt]
  skip_before_action :authenticate_super_user, only: [:receipt]

  def index
    @subscription = Current.business_owner.subscription
    
    # プラン課金履歴を取得
    subscription_charges = Current.business_owner.subscription_charges
      .finished
      .displayable_in_history
      .includes(:plan)
      .where("created_at >= ?", 1.year.ago)
    
    # LINE通知課金履歴を取得
    line_notice_charges = Current.business_owner.line_notice_charges
      .where(state: :completed)
      .where("created_at >= ?", 1.year.ago)
    
    # 両方を結合して時系列にソート
    @charges = (subscription_charges.to_a + line_notice_charges.to_a).sort_by(&:created_at).reverse
    
    @refundable = @subscription.refundable?
  end

  def upgrade_preview
    begin
      Rails.logger.info "Upgrade preview called with params: #{params.inspect}"
      
      new_plan = Plan.find_by!(level: params[:plan])
      unless new_plan
        Rails.logger.error "Plan not found: #{params[:plan]}"
        render json: { error: "プランが見つかりませんでした" }, status: :not_found
        return
      end
      
      rank = params[:rank].to_i
      subscription = Current.business_owner.subscription
      
      # 新プランの料金を取得
      price_outcome = Plans::Price.run(user: Current.business_owner, plan: new_plan, rank: rank)
      unless price_outcome.valid?
        Rails.logger.error "Price calculation failed: #{price_outcome.errors.full_messages.join(', ')}"
        render json: { error: "プランの料金を取得できませんでした: #{price_outcome.errors.full_messages.join(', ')}" }, status: :unprocessable_entity
        return
      end
      new_plan_price, _ = price_outcome.result
      
      # 既存プランの残存価値を取得
      residual_value_outcome = Subscriptions::ResidualValue.run(user: Current.business_owner)
      unless residual_value_outcome.valid?
        Rails.logger.error "Residual value calculation failed: #{residual_value_outcome.errors.full_messages.join(', ')}"
        render json: { error: "残存価値を取得できませんでした: #{residual_value_outcome.errors.full_messages.join(', ')}" }, status: :unprocessable_entity
        return
      end
      residual_value = residual_value_outcome.result
      
      # アップグレード時、新プランの料金を残りの契約期間で日割り計算
      if subscription.in_paid_plan && (last_charge = Current.business_owner.subscription_charges.last_plan_charged)
        new_plan_price = new_plan_price * Rational(last_charge.expired_date - Subscription.today, last_charge.expired_date - last_charge.charge_date)
      end
      
      charge_amount = new_plan_price - residual_value
      unless charge_amount.positive?
        charge_amount = new_plan_price
      end
      
      # 次回のチャージ日（現在の契約終了日）
      next_charge_date = subscription.expired_date
      
      # 次回以降のチャージ金額（新プランの通常料金）
      next_charge_amount, _ = Plans::Price.run!(user: Current.business_owner, plan: new_plan, rank: rank)
      
      result = {
        current_charge_amount: charge_amount.format,
        next_charge_date: next_charge_date ? next_charge_date.strftime("%Y年%m月%d日") : nil,
        next_charge_amount: next_charge_amount.format
      }
      
      Rails.logger.info "Upgrade preview result: #{result.inspect}"
      render json: result
    rescue => e
      Rails.logger.error "Upgrade preview error: #{e.class} - #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      Rollbar.error(e, "Upgrade preview failed", params: params)
      render json: { error: "情報の取得に失敗しました: #{e.message}" }, status: :internal_server_error
    end
  end

  def create
    new_plan = Plan.find_by!(level: params[:plan])

    outcome =
      if new_plan.business_level?
        Plans::SubscribeBusinessPlan.run(user: Current.business_owner, authorize_token: params[:token], payment_intent_id: params[:payment_intent_id])
      elsif new_plan.is_child?
        Plans::SubscribeChildPlan.run(
          user: Current.business_owner,
          plan: new_plan,
          rank: params[:rank],
          authorize_token: params[:token],
          change_immediately: params[:change_immediately],
          payment_intent_id: params[:payment_intent_id]
        )
      else
        Plans::Subscribe.run(
          user: Current.business_owner,
          plan: new_plan,
          rank: params[:rank],
          authorize_token: params[:token],
          change_immediately: params[:change_immediately],
          payment_intent_id: params[:payment_intent_id]
        )
      end

    if outcome.invalid?
      Rollbar.error(
        "Payment create failed",
        errors_messages: outcome.errors.full_messages.join(", "),
        errors_details: outcome.errors.details,
        params: params
      )

      error_with_client_secret = find_error_with_client_secret(outcome)
      
      # エラータイプを取得（:planキーから最初のエラーを取得）
      plan_error = outcome.errors.details[:plan]&.first || {}
      user_error = outcome.errors.details[:user]&.first || {}
      error_type = plan_error[:error] || user_error[:error] || outcome.errors.details.values.flatten.first&.dig(:error)
      
      # Stripeエラーコードとメッセージを取得（planとuserの両方をチェック）
      stripe_error_code = plan_error[:stripe_error_code] || user_error[:stripe_error_code]
      stripe_error_message = plan_error[:stripe_error_message] || user_error[:stripe_error_message]
      user_message = plan_error[:user_message] || user_error[:user_message]
      
      # ユーザー向けメッセージのみをフロントに送信（詳細はDBに記録済み）
      display_message = user_message || outcome.errors.full_messages.join("")

      render json: {
         message: display_message,
         error_type: error_type,
         stripe_error_code: stripe_error_code,
         stripe_error_message: stripe_error_message,
         client_secret: error_with_client_secret[:client_secret],
         payment_intent_id: error_with_client_secret[:payment_intent_id],
         setup_intent_id: error_with_client_secret[:setup_intent_id]
      }, status: :unprocessable_entity
    else
      redirect_path = lines_user_bot_settings_plans_path(business_owner_id: business_owner_id)
      
      # プラン契約かアップグレードかを判断してflashメッセージを設定
      subscription = Current.business_owner.subscription
      current_plan = subscription.current_plan
      current_plan_level = Plan.permission_level(current_plan.level)
      new_plan_level = Plan.permission_level(new_plan.level)
      
      # プランレベルの順序を定義
      plan_order = ["free", "basic", "premium"]
      current_index = plan_order.index(current_plan_level)
      new_index = plan_order.index(new_plan_level)
      
      # メッセージタイプとメッセージを設定
      if current_plan_level == "free"
        flash[:notice] = "プランの契約が完了しました"
      elsif new_index && current_index && new_index > current_index
        flash[:notice] = "プランのアップグレードが完了しました"
      else
        flash[:notice] = "プランの変更が完了しました"
      end
      
      # social_service_user_idをURLに追加
      # if current_social_user&.social_service_user_id
      #   redirect_path += "?social_service_user_id=#{current_social_user.social_service_user_id}"
      # elsif params[:social_service_user_id].present?
      #   redirect_path += "?social_service_user_id=#{params[:social_service_user_id]}"
      # end
      render json: { 
        redirect_path: redirect_path
      }
    end
  end

  def change_card
    outcome = Payments::StoreStripeCustomer.run(
      user: Current.business_owner,
      authorize_token: params[:token],
      setup_intent_id: params[:setup_intent_id]
    )

    if outcome.invalid?
      # Check if this is a 3DS case requiring client-side action
      if outcome.errors.details.dig(:user)&.any? { |error| error[:error] == :requires_action }
        user_error = outcome.errors.details[:user].find { |error| error[:error] == :requires_action }
        render json: {
          message: outcome.errors.full_messages.join(""),
          client_secret: user_error[:client_secret],
          setup_intent_id: user_error[:setup_intent_id]
        }, status: :unprocessable_entity
      else
        render json: {
          message: outcome.errors.full_messages.join("")
        }, status: :unprocessable_entity
      end
    else
      render json: {
        redirect_to: lines_user_bot_settings_path(business_owner_id: business_owner_id)
      }
    end
  end

  def refund
    outcome = Subscriptions::Refund.run(user: Current.business_owner)

    if outcome.valid?
      flash[:notice] = I18n.t("settings.plans.payment.refund_successfully_message")
    else
      flash[:alert] =  I18n.t("settings.plans.payment.refund_failed_message")
    end

    redirect_to lines_user_bot_settings_payments_path(business_owner_id: business_owner_id)
  end

  def receipt
    user_id = MessageEncryptor.decrypt(params[:encrypted_user_id])
    user = User.find(user_id)
    
    # SubscriptionChargeまたはLineNoticeChargeを取得
    if params[:type] == 'line_notice_charge'
      @charge = user.line_notice_charges.find(params[:id])
      @charge_type = 'line_notice_charge'
    else
      @charge = user.subscription_charges.find(params[:id])
      @charge_type = 'subscription_charge'
    end
    
    @receipient_name = user.name

    options = {
      template: "settings/payments/receipt",
      pdf: "subscription_receipt",
      title: @charge.created_at.to_date.to_s,
      show_as_html: params.key?('debug'),
      page_width: 210,
      page_height: 297,
      lowquality: Rails.env.development?,
      margin: {
        top: 22,
        left: 20,
        right: 20,
        bottom: 0
      }
    }

    render options
  end

  def downgrade
    user = Current.business_owner
    
    # 選択されたプランを取得（パラメータがない場合は無料プランへのダウングレードとみなす）
    if params[:plan].present?
      plan = Plan.find_by!(level: params[:plan])
      rank = params[:rank].to_i || 0
      
      # 無料プランへのダウングレードの場合
      if plan.free_level?
        outcome = Subscriptions::Unsubscribe.run(user: user)
      else
        # 有料プラン間のダウングレードの場合、次回請求時に新プランで請求されるようにnext_planを設定
        outcome = Plans::Subscribe.run(
          user: user,
          plan: plan,
          rank: rank,
          change_immediately: false  # 次回請求時に変更
        )
      end
      
      unless outcome.valid?
        flash[:alert] = outcome.errors.full_messages.join(", ")
      else
        flash[:notice] = "プランのダウングレード予約が完了しました"
      end
    else
      # プランが指定されていない場合は無料プランへのダウングレード
      outcome = Subscriptions::Unsubscribe.run(user: user)
      if outcome.valid?
        flash[:notice] = "プランのダウングレード予約が完了しました"
      end
    end

    # プラン選択画面にリダイレクト
    redirect_path = lines_user_bot_settings_plans_path(business_owner_id: business_owner_id)
    
    # social_service_user_idをURLに追加
    # query_params = []
    # if current_social_user&.social_service_user_id
    #   query_params << "social_service_user_id=#{current_social_user.social_service_user_id}"
    # elsif params[:social_service_user_id].present?
    #   query_params << "social_service_user_id=#{params[:social_service_user_id]}"
    # end
    
    # # クエリパラメータを追加
    # if query_params.any?
    #   redirect_path += "?#{query_params.join('&')}"
    # end
    
    # プランメニューへのアンカーリンクを追加（URLの最後）
    #redirect_path += "#plans-menu-item"
    
    redirect_to redirect_path
  end

  def cancel_downgrade_reservation
    user = Current.business_owner
    subscription = user.subscription
    
    # 同日中の制限をチェック
    if plan_change_restricted_today?
      flash[:alert] = "プラン変更は1日1回までとなります"
      redirect_to lines_user_bot_settings_plans_path(business_owner_id: business_owner_id)
      return
    end
    
    if subscription.next_plan_id.present?
      next_plan = subscription.next_plan
      subscription.update(next_plan_id: nil)
      
      # ダウングレードキャンセルのsubscription_chargeを作成（同日中の制限チェック用）
      user.subscription_charges.create!(
        plan: next_plan,
        rank: subscription.rank,
        amount_cents: 0,
        amount_currency: user.currency || "JPY",
        charge_date: Subscription.today,
        manual: true,
        state: :completed,
        order_id: OrderId.generate,
        details: {
          type: SubscriptionCharge::TYPES[:downgrade_cancellation],
          plan_name: next_plan.name,
          rank: subscription.rank
        }
      )
      
      flash[:notice] = "プランのダウングレード予約をキャンセルしました"
      redirect_to lines_user_bot_settings_plans_path(business_owner_id: business_owner_id)
    else
      render json: { success: false, message: "ダウングレード予約が存在しません" }, status: :unprocessable_entity
    end
  end

  private

  def plan_change_restricted_today?
    user = Current.business_owner
    subscription = user.subscription
    
    # 現在有料プランにいる場合のみチェック
    return false unless subscription.in_paid_plan
    
    # 今日完了したmanualなchargeを取得（初回契約またはアップグレード）
    today_charge = user.subscription_charges
                      .finished
                      .manual
                      .where(charge_date: Subscription.today)
                      .where.not("details ->> 'type' = ?", SubscriptionCharge::TYPES[:downgrade_reservation])
                      .where.not("details ->> 'type' = ?", SubscriptionCharge::TYPES[:downgrade_cancellation])
                      .order(created_at: :desc)
                      .first
    
    # 今日完了したmanualなchargeがあれば、同日中のプラン変更を制限
    return true if today_charge.present?
    
    # 今日作成されたダウングレード予約・キャンセルのchargeをチェック
    today_downgrade_charge = user.subscription_charges
                                  .finished
                                  .where(charge_date: Subscription.today)
                                  .where("details ->> 'type' IN (?, ?)",
                                         SubscriptionCharge::TYPES[:downgrade_reservation],
                                         SubscriptionCharge::TYPES[:downgrade_cancellation])
                                  .order(created_at: :desc)
                                  .first
    
    # 今日ダウングレード予約・キャンセルがあれば、同日中のプラン変更を制限
    today_downgrade_charge.present?
  end
end

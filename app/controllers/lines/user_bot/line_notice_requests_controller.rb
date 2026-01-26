# frozen_string_literal: true

class Lines::UserBot::LineNoticeRequestsController < Lines::UserBotDashboardController
  before_action :set_line_notice_request, only: [:show, :approve, :success]

  # GET /lines/user_bot/owner/:business_owner_id/line_notice_requests/:id
  # リクエスト確認画面
  def show
    @reservation = @line_notice_request.reservation
    @customer = @line_notice_request.customer
    
    # すでに承認済みの場合は成功画面にリダイレクト
    if @line_notice_request.approved?
      redirect_to success_lines_user_bot_line_notice_request_path(
        business_owner_id: business_owner_id,
        id: @line_notice_request.id
      )
      return
    end
    
    # 承認不可の場合（拒否済み・期限切れなど）
    unless @line_notice_request.can_be_approved?
      flash[:alert] = I18n.t('line_notice_requests.errors.cannot_be_approved')
      redirect_to lines_user_bot_schedules_path(business_owner_id: business_owner_id)
      return
    end
    
    # 初回無料かどうかを判定
    @is_free_trial = Current.business_owner.line_notice_free_trial_available?
    @charge_amount = @is_free_trial ? 0 : LineNoticeCharge::LINE_NOTICE_CHARGE_AMOUNT_JPY
    
    # デバッグログ
    Rails.logger.info("[LineNoticeRequestsController#show] user_id: #{Current.business_owner.id}")
    Rails.logger.info("[LineNoticeRequestsController#show]   is_free_trial: #{@is_free_trial}")
    Rails.logger.info("[LineNoticeRequestsController#show]   existing free_trial charges count: #{Current.business_owner.line_notice_charges.free_trials.successful.count}")
    Rails.logger.info("[LineNoticeRequestsController#show]   all charges count: #{Current.business_owner.line_notice_charges.count}")
  end

  # POST /lines/user_bot/owner/:business_owner_id/line_notice_requests/:id/approve
  # リクエスト承認処理
  def approve
    # すでに承認済みの場合は成功画面にリダイレクト
    if @line_notice_request.approved?
      redirect_to success_lines_user_bot_line_notice_request_path(
        business_owner_id: business_owner_id,
        id: @line_notice_request.id
      )
      return
    end
    
    # 承認不可の場合
    unless @line_notice_request.can_be_approved?
      flash[:alert] = I18n.t('line_notice_requests.errors.cannot_be_approved')
      redirect_to lines_user_bot_schedules_path(business_owner_id: business_owner_id)
      return
    end
    
    # 初回無料かどうかを判定
    is_free_trial = Current.business_owner.line_notice_free_trial_available?

    if is_free_trial
      # 無料の場合、そのまま承認
      outcome = LineNoticeRequests::Approve.run(
        line_notice_request: @line_notice_request,
        user: Current.business_owner,
        is_free_trial: true
      )

      if outcome.valid?
        redirect_to success_lines_user_bot_line_notice_request_path(
          business_owner_id: business_owner_id,
          id: @line_notice_request.id
        )
      else
        flash[:alert] = outcome.errors.full_messages.join(", ")
        redirect_to lines_user_bot_line_notice_request_path(
          business_owner_id: business_owner_id,
          id: @line_notice_request.id
        )
      end
    else
      # 有料の場合、決済処理
      payment_method_id = params[:payment_method_id]
      
      unless payment_method_id.present?
        render json: { 
          error: I18n.t('line_notice_requests.errors.payment_method_required') 
        }, status: :unprocessable_entity
        return
      end

      outcome = LineNoticeRequests::Approve.run(
        line_notice_request: @line_notice_request,
        user: Current.business_owner,
        is_free_trial: false,
        payment_method_id: payment_method_id
      )

      if outcome.valid?
        render json: {
          status: 'success',
          redirect_url: success_lines_user_bot_line_notice_request_path(
            business_owner_id: business_owner_id,
            id: @line_notice_request.id
          )
        }
      else
        # エラー詳細を取得（プラン決済と同様のフォーマット）
        error_details = outcome.errors.details[:payment]&.first || outcome.errors.details[:user]&.first || {}
        
        # ユーザー向けメッセージを優先的に使用
        user_message = error_details[:user_message] || outcome.errors.full_messages.first || "決済に失敗しました。"
        
        render json: { 
          message: user_message,
          error_type: error_details[:error]&.to_s || 'payment_failed',
          stripe_error_code: error_details[:stripe_error_code],
          stripe_error_message: error_details[:stripe_error_message],
          client_secret: error_details[:client_secret],
          payment_intent_id: error_details[:payment_intent_id],
          setup_intent_id: error_details[:setup_intent_id]
        }, status: :unprocessable_entity
      end
    end
  end

  # GET /lines/user_bot/owner/:business_owner_id/line_notice_requests/:id/success
  # 承認完了画面
  def success
    @reservation = @line_notice_request.reservation
    @customer = @line_notice_request.customer
    @line_notice_charge = @line_notice_request.line_notice_charge
  end

  private

  def set_line_notice_request
    @line_notice_request = Current.business_owner.line_notice_requests.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to lines_user_bot_schedules_path(business_owner_id: business_owner_id), 
                alert: I18n.t('line_notice_requests.errors.not_found')
  end
end


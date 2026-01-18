# frozen_string_literal: true

class Lines::UserBot::LineNoticeRequestsController < Lines::UserBotDashboardController
  before_action :set_line_notice_request, only: [:show, :approve, :success]

  # GET /lines/user_bot/owner/:business_owner_id/line_notice_requests/:id
  # リクエスト確認画面
  def show
    @reservation = @line_notice_request.reservation
    @customer = @line_notice_request.customer
    
    # 初回無料かどうかを判定
    @is_free_trial = Current.business_owner.line_notice_free_trial_available?
    @charge_amount = @is_free_trial ? 0 : LineNoticeCharge::LINE_NOTICE_CHARGE_AMOUNT_JPY
  end

  # POST /lines/user_bot/owner/:business_owner_id/line_notice_requests/:id/approve
  # リクエスト承認処理
  def approve
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
        render json: { 
          error: outcome.errors.full_messages.join(", ")
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


# frozen_string_literal: true

require "message_encryptor"

class LineNoticeRequestsController < ActionController::Base
  include ControllerHelpers
  include ProductLocale
  include UserBotCookies

  protect_from_forgery with: :exception, prepend: true
  skip_before_action :verify_authenticity_token, only: [:callback]
  skip_before_action :track_ahoy_visit
  skip_before_action :set_locale
  before_action :load_reservation, only: [:new, :callback, :success]
  before_action :set_locale
  before_action :check_reservation_eligibility, only: [:new]

  layout "booking"

  # GET /line_notice_requests/new?reservation_id=123
  # リクエスト説明画面
  def new
    @existing_request = LineNoticeRequest.where(status: [:pending, :approved]).find_by(reservation_id: @reservation.id)
  end

  # GET /line_notice_requests/callback (LINE OAuth後のコールバック)
  # LINE連携完了後、リクエストを作成
  def callback
    # LINE OAuth から返された social_user_id を取得
    social_user_id = params[:social_user_id]
    customer_id = params[:customer_id]
    
    unless social_user_id.present?
      redirect_to line_notice_requests_path(reservation_id: @reservation.id), alert: I18n.t("line_notice_requests.errors.line_auth_failed")
      return
    end

    # SocialCustomer を取得（customer_idとsocial_user_idの両方で検索して、正しいレコードを取得）
    social_customer = if customer_id.present?
      # customer_idとsocial_user_idの両方で検索（最新のレコードを取得）
      SocialCustomer.where(social_user_id: social_user_id, customer_id: customer_id).order(created_at: :desc).first
    else
      # customer_idがない場合は、social_user_idだけで検索
      SocialCustomer.find_by(social_user_id: social_user_id)
    end
    
    Rails.logger.info("[LineNoticeRequestsController] callback - social_customer検索結果:")
    Rails.logger.info("[LineNoticeRequestsController]   social_user_id: #{social_user_id}")
    Rails.logger.info("[LineNoticeRequestsController]   customer_id (param): #{customer_id || 'nil'}")
    Rails.logger.info("[LineNoticeRequestsController]   social_customer found: #{social_customer.present? ? "ID=#{social_customer.id}" : 'nil'}")
    Rails.logger.info("[LineNoticeRequestsController]   social_customer.customer: #{social_customer&.customer.present? ? "ID=#{social_customer.customer.id}" : 'nil'}")
    
    unless social_customer&.customer
      Rails.logger.warn("[LineNoticeRequestsController] ⚠️ social_customer.customer が nil のため、TOPにリダイレクト")
      redirect_to line_notice_requests_path(reservation_id: @reservation.id), alert: I18n.t("line_notice_requests.errors.customer_not_found")
      return
    end

    # リクエスト作成
    outcome = LineNoticeRequests::Create.run(
      reservation: @reservation,
      customer: social_customer.customer
    )

    if outcome.valid?
      # 友だち追加URLを確認画面に渡す
      @line_add_friend_url = @reservation.user.social_account.add_friend_url
      redirect_to success_line_notice_requests_path(request_id: outcome.result.id)
    else
      redirect_to line_notice_requests_path(reservation_id: @reservation.id), alert: outcome.errors.full_messages.join(", ")
    end
  end

  # GET /line_notice_requests/success?request_id=123
  # リクエスト完了画面
  def success
    # @reservationと@requestはload_reservationで設定済み
  end

  private

  def product_social_user
    @reservation&.user&.social_user
  end

  def load_reservation
    if params[:reservation_id].present?
      @reservation = Reservation.find(params[:reservation_id])
    elsif params[:request_id].present?
      @request = LineNoticeRequest.find(params[:request_id])
      @reservation = @request.reservation
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: I18n.t("line_notice_requests.errors.reservation_not_found")
  end

  def check_reservation_eligibility
    # 店舗が無料プランであることを確認
    unless @reservation.user.subscription.current_plan.free_level?
      redirect_to root_path, alert: I18n.t("line_notice_requests.errors.not_free_plan")
    end
  end

  def line_oauth_url
    # LINE OAuth URL を生成（店舗のSocialAccountを使用）
    oauth_social_account_id = MessageEncryptor.encrypt(@reservation.user.social_account.id.to_s)
    oauth_redirect_to_url = callback_line_notice_requests_url(reservation_id: @reservation.id)
    
    # 予約に紐づく最初のcustomer_idを取得して渡す（SocialCustomers::FromOmniauthで自動紐付けするため）
    customer_id = @reservation.customers.first&.id
    
    return nil unless customer_id.present?
    
    # bot_prompt=aggressive: LINE Login時に店舗の公式アカウントを友だち追加する画面を表示（チェックON状態）
    # prompt=consent: 毎回同意画面を表示
    "/users/auth/line?oauth_social_account_id=#{CGI.escape(oauth_social_account_id)}&oauth_redirect_to_url=#{CGI.escape(oauth_redirect_to_url)}&customer_id=#{customer_id}&prompt=consent&bot_prompt=aggressive"
  end
  helper_method :line_oauth_url
end


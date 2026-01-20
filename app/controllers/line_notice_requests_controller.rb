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
    @existing_request = LineNoticeRequest.pending.find_by(reservation_id: @reservation.id)
  end

  # GET /line_notice_requests/callback (LINE OAuth後のコールバック)
  # LINE連携完了後、リクエストを作成
  def callback
    # LINE OAuth から返された social_user_id を取得
    social_user_id = params[:social_user_id]
    
    unless social_user_id.present?
      redirect_to line_notice_requests_path(reservation_id: @reservation.id), alert: I18n.t("line_notice_requests.errors.line_auth_failed")
      return
    end

    # SocialCustomer を取得または作成
    social_customer = SocialCustomer.find_by(social_user_id: social_user_id)
    
    unless social_customer&.customer
      redirect_to line_notice_requests_path(reservation_id: @reservation.id), alert: I18n.t("line_notice_requests.errors.customer_not_found")
      return
    end

    # リクエスト作成
    outcome = LineNoticeRequests::Create.run(
      reservation: @reservation,
      customer: social_customer.customer
    )

    if outcome.valid?
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
    
    "/users/auth/line?oauth_social_account_id=#{CGI.escape(oauth_social_account_id)}&oauth_redirect_to_url=#{CGI.escape(oauth_redirect_to_url)}"
  end
  helper_method :line_oauth_url
end


# frozen_string_literal: true

require "message_encryptor"

# メール/SMS内のLINE連携リンクからGETでアクセスされた際に、
# OmniAuthのPOST要件を満たすため、自動的にPOSTフォームを送信する中継ページ
class LineConnectController < ActionController::Base
  include ProductLocale

  layout "booking"
  skip_before_action :track_ahoy_visit

  # GET /line_connect?oauth_social_account_id=...&oauth_redirect_to_url=...&customer_id=...&prompt=...&bot_prompt=...
  def show
    @oauth_social_account_id = params[:oauth_social_account_id]
    @oauth_redirect_to_url = params[:oauth_redirect_to_url]
    @customer_id = params[:customer_id]
    @prompt = params[:prompt]
    @bot_prompt = params[:bot_prompt]

    # パラメータの検証
    unless @oauth_social_account_id.present?
      render plain: "Invalid request", status: :bad_request
      return
    end
  end

  private

  def product_social_user
    nil
  end
end

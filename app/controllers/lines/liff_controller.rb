# frozen_string_literal: true

require "liff_routing"

class Lines::LiffController < ActionController::Base
  protect_from_forgery with: :exception, prepend: true
  layout "user_bot_guest"
  skip_before_action :track_ahoy_visit

  # lines/liff
  def index
    I18n.locale = "ja"
    setup_liff('ja')
    render action: "redirect"
  end

  # lines/twliff
  def tw_index
    I18n.locale = "tw"
    setup_liff('tw')
    render action: "redirect"
  end

  private

  def setup_liff(locale)
    @liff_id = Rails.application.secrets[locale][:toruya_liff_id]
    @redirect_to = LiffRouting.url(params[:liff_path] || params["liff.state"], locale)
  end
end

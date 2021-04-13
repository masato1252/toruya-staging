# frozen_string_literal: true

require "liff_routing"

class Lines::LiffController < ActionController::Base
  protect_from_forgery with: :exception, prepend: true
  layout "user_bot_guest"
  skip_before_action :track_ahoy_visit

  def index
    # XXX: the redirected url would bring the line user id, called social_service_user_id from here
    @liff_id = Rails.application.secrets.toruya_liff_id
    @redirect_to = LiffRouting.url(params[:liff_path] || params["liff.state"])

    render action: "redirect"
  end
end

require "liff_routing"

class Lines::LiffController < ActionController::Base
  protect_from_forgery with: :exception, prepend: true
  layout "user_bot"

  def index
    if params["liff.state"]
      head :ok
      return
    end

    # XXX: the redirected url would bring the line user id, called social_service_user_id from here
    @liff_id = LiffRouting::LIFF_ID
    @redirect_to = LiffRouting.url(params[:liff_path])

    render action: "redirect"
  end
end

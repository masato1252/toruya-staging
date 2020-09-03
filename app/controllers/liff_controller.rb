class LiffController < ActionController::Base
  protect_from_forgery with: :exception, prepend: true
  layout "booking"

  def identify_line_user_for_connecting_shop_customer
    # @redirect_to has to match this format, the last variable must be line user_id
    # /lines/identify_shop_customer(/:social_user_id)
    @redirect_to = lines_identify_shop_customer_url
    @liff_id = "1654876625-z3PdqoW8"

    render action: "redirect"
  end
end

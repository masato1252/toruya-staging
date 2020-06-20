class LinesController < ActionController::Base
  def identify_shop_customer
    @social_customer = SocialCustomer.find_by!(social_user_id: params[:social_user_id])
  end
end

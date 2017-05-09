module ViewHelpers
  extend ActiveSupport::Concern

  included do
    skip_before_action :verify_authenticity_token
    protect_from_forgery prepend: true, with: :exception
    before_action :authenticate_user!
    helper_method :shops
    helper_method :shop
    helper_method :super_user
  end

  def shops
    @shops ||= current_user.shops
  end

  # Use callbacks to share common setup or constraints between actions.
  def shop
    @shop ||= super_user.shops.find_by(id: params[:shop_id])
  end

  def super_user
    current_user
  end
end

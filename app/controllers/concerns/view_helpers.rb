module ViewHelpers
  extend ActiveSupport::Concern

  included do
    skip_before_action :verify_authenticity_token
    protect_from_forgery prepend: true, with: :exception
    before_action :authenticate_user!
    before_action :staffs_of_super_user
    helper_method :shops
    helper_method :shop
    helper_method :super_user
  end

  def shops
    @shops ||= super_user.shops
  end

  # Use callbacks to share common setup or constraints between actions.
  def shop
    @shop ||= Shop.find_by(id: params[:shop_id])
  end

  def super_user
    @super_user ||= User.find_by(id: params[:user_id]) || shop.try(:user) || current_user
  end

  def staffs_of_super_user
    if super_user && super_user != current_user && !super_user.owner_staff_accounts.where(user_id: current_user.id).exists?
      redirect_to root_path, alert: "Not shop owner or staff"
    end
  end
end

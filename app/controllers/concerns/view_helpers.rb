module ViewHelpers
  extend ActiveSupport::Concern

  included do
    skip_before_action :verify_authenticity_token
    protect_from_forgery prepend: true, with: :exception
    before_action :authenticate_user!
    helper_method :shops
    helper_method :shop
    helper_method :staffs
    helper_method :staff
    helper_method :super_user
  end

  def shops
    @shops ||= current_user.shops
  end

  # Use callbacks to share common setup or constraints between actions.
  def shop
    @shop ||= super_user.shops.find_by(id: params[:shop_id]) || super_user.shops.first
  end

  def staffs
    @staffs ||= current_user.staffs.active
  end

  # Use callbacks to share common setup or constraints between actions.
  def staff
    @staff ||= super_user.staffs.find_by(id: params[:staff_id]) || super_user.staffs.active.first
  end

  def super_user
    current_user
  end
end

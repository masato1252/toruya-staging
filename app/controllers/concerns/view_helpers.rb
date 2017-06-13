module ViewHelpers
  extend ActiveSupport::Concern

  included do
    skip_before_action :verify_authenticity_token
    protect_from_forgery prepend: true, with: :exception
    before_action :set_header_setting
    before_action :authenticate_user!
    helper_method :shops
    helper_method :shop
    helper_method :staffs
    helper_method :staff
    helper_method :super_user
  end

  def shops
    @shops ||= super_user.shops
  end

  def shop
    @shop ||= Shop.find_by(id: params[:shop_id])
  end

  def staffs
    @staffs ||= super_user.staffs.active
  end

  def staff
    @staff ||= super_user.staffs.find_by(id: params[:staff_id]) || super_user.owner_staff_accounts.find_by(user_id: current_user.id).try(:staff) || super_user.staffs.active.first
  end

  def super_user
    @super_user ||= User.find_by(id: params[:user_id]) || shop.try(:user) || current_user
  end

  def current_ability
    @current_ability ||= Ability.new(current_user, super_user)
  end

  def is_owner
    super_user == current_user
  end

  def set_header_setting
    @header_setting = true
  end
end

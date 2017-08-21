module ViewHelpers
  extend ActiveSupport::Concern

  included do
    skip_before_action :verify_authenticity_token
    protect_from_forgery prepend: true, with: :exception
    before_action :set_header_setting
    before_action :authenticate_user!
    before_action :authenticate_user_permission!
    helper_method :shops
    helper_method :shop
    helper_method :staffs
    helper_method :staff
    helper_method :super_user
  end

  def shops
    @shops ||= if can?(:manage, :all)
                 super_user.shops.order("id")
               else
                 current_user.current_staff(super_user).shops.order("id")
               end
  end

  def shop
    session[:shop_id] = params[:shop_id] if params[:shop_id]
    @shop ||= Shop.find_by(id: session[:shop_id])
  end

  def staffs
    @staffs = if can?(:manage, :all)
                super_user.staffs.active.order(:id)
              else
                super_user.staffs.active.joins(:shop_staffs).where("shop_staffs.shop_id": shop.id)
              end
  end

  def staff
    @staff ||= super_user.staffs.find_by(id: params[:staff_id]) || current_user.current_staff(super_user) || super_user.staffs.active.first
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

  def authenticate_user_permission!
    if !is_owner && !current_user.current_staff_account(super_user).try(:active?)
      head :not_found
    end
  end
end

module Authorization
  extend ActiveSupport::Concern

  included do
    protect_from_forgery prepend: true, with: :exception
    before_action :authenticate_user!
    before_action :where_user_are
    before_action :authenticate_super_user
  end

  def authenticate_super_user
    if current_user != super_user && current_user.current_staff(super_user).nil?
      redirect_to member_path, alert: "No permission"
    end
  end

  def where_user_are
    if params[:user_id] && params[:shop_id]
      session[:current_super_user_id] = params[:user_id]
      session[:current_shop_id] = params[:shop_id]
    elsif params[:shop_id]
      session[:current_shop_id] = params[:shop_id]
      session[:current_super_user_id] = shop.user_id
    elsif params[:user_id]
      session[:current_super_user_id] = params[:user_id]
      session[:current_shop_id] = nil if super_user.shop_ids.exclude?(session[:current_shop_id].to_i)
    else
      session[:current_super_user_id] = current_user.id
      session[:current_shop_id] = nil if super_user.shop_ids.exclude?(session[:current_shop_id].to_i)
    end
  end
end

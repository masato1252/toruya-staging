module UserBotAuthorization
  extend ActiveSupport::Concern

  included do
    protect_from_forgery prepend: true, with: :exception
    before_action :authenticate_current_user!
    before_action :where_user_are
    before_action :authenticate_super_user
  end

  def authenticate_current_user!
    unless current_user
      redirect_to LiffRouting.liff_url(:users_connect)
    end
  end

  def authenticate_super_user
    if current_user != super_user && current_user.current_staff(super_user).nil?
      redirect_to SiteRouting.new(view_context).member_path, alert: I18n.t("common.no_permission")
    end
  end

  def where_user_are
    if params[:user_id].present? && params[:shop_id].present?
      write_user_bot_cookies(:current_super_user_id, params[:user_id])
      write_user_bot_cookies(:current_shop_id, params[:shop_id])
    elsif params[:shop_id].present?
      write_user_bot_cookies(:current_shop_id, params[:shop_id])
      write_user_bot_cookies(:current_super_user_id, Shop.find(params[:shop_id]).user_id)
    elsif params[:user_id].present?
      write_user_bot_cookies(:current_super_user_id, params[:user_id])
      write_user_bot_cookies(:current_shop_id, nil) if User.find(params[:user_id]).shop_ids.exclude?(user_bot_cookies(:current_shop_id).to_i)
    else
      write_user_bot_cookies(:current_super_user_id, current_user.id)
      write_user_bot_cookies(:current_shop_id, nil) if current_user.shop_ids.exclude?(user_bot_cookies(:current_shop_id).to_i)
    end
  end
end

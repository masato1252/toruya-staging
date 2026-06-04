# frozen_string_literal: true

module AdminAccess
  extend ActiveSupport::Concern

  CHAT_OPERATOR_CONTROLLERS = %w[
    Admin::ChatsController
    Admin::MemosController
    Admin::SocialAccountsController
    Admin::SalePagesController
    Admin::BookingPagesController
    Admin::OnlineServiceCustomerRelationsController
    Admin::SubscriptionsController
    Admin::CustomMessagesController
  ].freeze

  included do
    before_action :require_admin_privilege!
    before_action :bootstrap_user_bot_cookies_from_devise_session
  end

  private

  def require_admin_privilege!
    user = current_user
    unless user
      redirect_to new_user_session_path, alert: I18n.t("devise.failure.unauthenticated")
      return
    end

    return if admin_privilege_allowed?(user)

    redirect_to root_path, alert: I18n.t("common.no_permission")
  end

  def admin_privilege_allowed?(user)
    if chat_operator_admin_access?
      user.super_admin? || user.can_admin_chat? || dev_or_staging_admin?
    else
      user.super_admin? || dev_or_staging_admin?
    end
  end

  def chat_operator_admin_access?
    return true if action_name == "logs"

    CHAT_OPERATOR_CONTROLLERS.include?(self.class.name)
  end

  def dev_or_staging_admin?
    Rails.env.development? || Rails.configuration.x.env.staging?
  end

  def bootstrap_user_bot_cookies_from_devise_session
    user = current_user
    return unless user
    return if user_bot_cookies(:current_user_id).present?

    write_user_bot_cookies(:current_user_id, user.id)

    social_service_user_id = user.social_user&.social_service_user_id
    return if social_service_user_id.blank?

    write_user_bot_cookies(:social_service_user_id, social_service_user_id)
  end
end

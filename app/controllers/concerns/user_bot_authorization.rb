# frozen_string_literal: true

module UserBotAuthorization
  extend ActiveSupport::Concern

  included do
    # protect_from_forgery prepend: true, with: :exception
    before_action :authenticate_current_user!
    before_action :authenticate_super_user
  end

  def authenticate_current_user!
    if current_user
      Current.social_user = current_social_user
      Current.user = current_user
    else
      redirect_to user_login_path
    end
  end

  def authenticate_super_user
    Current.business_owner = super_user || current_user
  end
end

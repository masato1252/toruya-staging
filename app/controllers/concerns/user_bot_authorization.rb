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
    if compat_read_data_plane?
      owner_id = params[:business_owner_id].presence&.to_i
      if owner_id.positive?
        session_data = compat_auth_session(owner_id: owner_id, current_user_id: current_user&.id)
        if session_data && session_data["owner_id"].to_i == owner_id
          Current.business_owner = User.find_by(id: owner_id) || current_user
          return
        end
      end
    end

    Current.business_owner = super_user || current_user
  end
end

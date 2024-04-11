# frozen_string_literal: true

class AdminController < ApplicationController
  include Devise::Controllers::Rememberable
  include ControllerHelpers
  include UserBotCookies

  def as_user
    user = User.find(params[:as_user_id])
    sign_out
    remember_me(user)
    sign_in(user)
    write_user_bot_cookies(:current_user_id, user.id)
    write_user_bot_cookies(:social_service_user_id, user.social_user&.social_service_user_id)

    redirect_to lines_user_bot_settings_path(user.id)
  end
end

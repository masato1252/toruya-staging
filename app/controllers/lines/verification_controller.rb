# frozen_string_literal: true

require "message_encryptor"
require "line_client"

class Lines::VerificationController < ActionController::Base
  layout "booking"
  before_action :current_user
  before_action :line_settings_required

  def show
    @login_api_ready = current_user.social_account&.login_api_verified?

    if @login_api_ready
      redirect_to lines_verification_message_api_status_path(encrypted_social_service_user_id: params[:encrypted_social_service_user_id])
      return
    end
  end

  def message_api_status
    @login_api_ready = current_user.social_account&.login_api_verified?

    if !@login_api_ready
      redirect_to lines_verification_path(encrypted_social_service_user_id: params[:encrypted_social_service_user_id])
      return
    end

    @message_api_ready = current_user.social_account&.message_api_verified?

    if !@message_api_ready
      Notifiers::Users::LineSettings::LineLoginVerificationMessage.run(receiver: current_user.social_user)
      Notifiers::Users::LineSettings::LineLoginVerificationVideo.run(receiver: current_user.social_user)
      outcome = Notifiers::Customers::LineSettings::LineLoginVerificationFlex.run(receiver: current_user.owner_social_customer)

      if outcome.invalid?
        Notifiers::Users::LineSettings::VerifyFailedMessage.run(receiver: current_user.social_user)
        Notifiers::Users::LineSettings::VerifyFailedVideo.run(receiver: current_user.social_user)
      end
    end
  end

  def current_user
    @current_user ||= SocialUser.find_by(social_service_user_id: MessageEncryptor.decrypt(params[:encrypted_social_service_user_id]))&.user
  end
  helper_method :current_user

  private

  def line_settings_required
    if !current_user.social_account&.is_login_available?
      redirect_to login_api_lines_user_bot_settings_social_account_path
      return
    end

    if !current_user.social_account&.bot_data_finished?
      redirect_to message_api_lines_user_bot_settings_social_account_path
      return
    end
  end
end

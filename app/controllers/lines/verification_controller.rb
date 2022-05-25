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

      line_response = LineClient.flex(
        current_user.owner_social_customer,
        LineMessages::FlexTemplateContainer.template(
          altText: I18n.t("line_verification.confirmation_message.title1"),
          contents: LineMessages::FlexTemplateContent.two_header_card(
            title1: I18n.t("line_verification.confirmation_message.title1"),
            title2: I18n.t("line_verification.confirmation_message.title2"),
            action_templates: [
              LineActions::Message.new(
                label: I18n.t("line_verification.confirmation_message.action"),
                text: current_user.social_user.social_service_user_id,
                btn: 'primary'
              ).template
            ]
          )
        )
      )

      # send successfully as sign to interify
      if line_response.is_a?(Net::HTTPOK)
        SocialMessages::Create.run(
          social_customer: current_user.owner_social_customer,
          content: I18n.t("line_verification.confirmation_message.title1"),
          readed: true,
          message_type: SocialMessage.message_types[:bot],
          send_line: false
        )
      elsif line_response.is_a?(Net::HTTPBadRequest)
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

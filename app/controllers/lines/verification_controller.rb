# frozen_string_literal: true

require "message_encryptor"
require "line_client"

class Lines::VerificationController < ActionController::Base
  layout "booking"
  before_action :current_user
  before_action :line_settings_required

  def show
    @login_api_ready = current_user.social_account&.login_api_verified?
    @message_api_ready = current_user.social_account&.message_api_verified?

    if @login_api_ready && !@message_api_ready
      line_response = LineClient.flex(
        current_user.owner_social_customer,
        LineMessages::FlexTemplateContainer.template(
          altText: 'Customer test message',
          contents: LineMessages::FlexTemplateContent.content5(
            title1: 'header1',
            title2: 'header2',
            action_templates: [ LineActions::Message.new(text: 'Customer test message', btn: 'primary').template ]
          )
        )
      )

      if line_response.is_a?(Net::HTTPOK)
        SocialMessages::Create.run(
          social_customer: current_user.owner_social_customer,
          content: 'Owner test message',
          readed: true,
          message_type: SocialMessage.message_types[:bot],
          send_line: false
        )

        # redirect back to verification page to check message_api again
        redirect_to lines_verification_path(params[:encrypted_social_service_user_id])
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

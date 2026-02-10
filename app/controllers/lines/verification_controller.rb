# frozen_string_literal: true

require "message_encryptor"
require "line_client"

class Lines::VerificationController < ActionController::Base
  before_action :current_user
  before_action :line_settings_required
  include ProductLocale
  layout "booking"

  def show
    @login_api_ready = current_user.social_account&.login_api_verified?

    if @login_api_ready
      redirect_to lines_verification_message_api_status_path(encrypted_social_service_user_id: params[:encrypted_social_service_user_id], encrypted_business_owner_id: MessageEncryptor.encrypt(current_user.id))
      return
    end
  end

  def message_api_status
    @login_api_ready = current_user.social_account&.login_api_verified?

    if !@login_api_ready
      redirect_to lines_verification_path(encrypted_social_service_user_id: params[:encrypted_social_service_user_id], encrypted_business_owner_id: MessageEncryptor.encrypt(current_user.id))
      return
    end

    if !current_user.social_account.channel_secret_correctness?
      Notifiers::Users::LineSettings::LineChannelSecretIncorrectMessage.run(receiver: current_user.social_user)
      return
    end

    @message_api_ready = current_user.social_account&.message_api_verified?

    if !@message_api_ready
      Notifiers::Users::LineSettings::LineLoginVerificationMessage.run(receiver: current_user.social_user)
      Notifiers::Users::LineSettings::LineLoginVerificationVideo.run(receiver: current_user.social_user)

      all_requests_result = []
      # IMPORTANT: Somehow even customer use the same line account, they have different id from line login and join in by chat.
      # So if which one we could send the message successfully, that one is the real owner customer
      current_user.social_customers.where(social_user_name: current_user.owner_social_customer.social_user_name).each do |social_customer|
        outcome = Notifiers::Customers::LineSettings::LineLoginVerificationFlex.run(receiver: social_customer)
        all_requests_result << outcome.valid?

        if outcome.valid?
          social_customer.update_columns(is_owner: true)
          profile = social_customer.user.profile
          SocialCustomers::FindOrCreateCustomer.run(
            social_customer: social_customer,
            customer_last_name: profile.last_name,
            customer_first_name: profile.first_name,
            customer_phonetic_last_name: profile.phonetic_last_name,
            customer_phonetic_first_name: profile.phonetic_first_name,
            customer_phone_number: profile.phone_number
          )
        else
          social_customer.update_columns(is_owner: false)
        end
      end

      if all_requests_result.all?(false)
        Notifiers::Users::LineSettings::VerifyFailedMessage.run(receiver: current_user.social_user)
        Notifiers::Users::LineSettings::VerifyFailedVideo.run(receiver: current_user.social_user)
      elsif all_requests_result.any?(true)
        # テスト送信が成功し、message_api_verified?がtrueになった場合
        # 即座に完了メッセージを送信
        if current_user.social_account&.message_api_verified?
          Notifiers::Users::LineSettingsVerified.run(receiver: current_user)
        end
      end
    end

    if current_user.social_account&.line_settings_verified?
      SocialAccounts::RichMenus::SwitchToOfficial.run(social_account: current_user.social_account)
    end
  end

  def current_user
    @current_user ||=
      if params[:encrypted_business_owner_id]
        User.find_by(id: MessageEncryptor.decrypt(params[:encrypted_business_owner_id]))
      else
        SocialUser.find_by(social_service_user_id: MessageEncryptor.decrypt(params[:encrypted_social_service_user_id]))&.user
      end
  end
  helper_method :current_user

  private

  def line_settings_required
    if !current_user&.social_account&.is_login_available?
      redirect_to login_api_lines_user_bot_settings_social_account_path(business_owner_id: current_user&.id)
      return
    end

    if !current_user&.social_account&.bot_data_finished?
      redirect_to message_api_lines_user_bot_settings_social_account_path(business_owner_id: current_user&.id)
      return
    end
  end

  def product_social_user
    current_user.social_user
  end
end

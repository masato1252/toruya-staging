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
      target_social_account = current_user.social_account
      candidates = verification_candidates(target_social_account)

      Rails.logger.info("[LineVerification] Starting verification: user_id=#{current_user.id}, social_account_id=#{target_social_account.id}, candidates=#{candidates.count}")

      candidates.each do |social_customer|
        Rails.logger.info("[LineVerification] Trying Flex send: social_customer_id=#{social_customer.id}, uid=#{social_customer.social_user_id}")

        outcome = Notifiers::Customers::LineSettings::LineLoginVerificationFlex.run(receiver: social_customer)
        sent_ok = outcome.valid?
        all_requests_result << sent_ok

        Rails.logger.info("[LineVerification] Flex send result: social_customer_id=#{social_customer.id}, uid=#{social_customer.social_user_id}, success=#{sent_ok}")

        if sent_ok
          social_customer.update_columns(is_owner: true)
          profile = social_customer.user.profile
          foc_outcome = SocialCustomers::FindOrCreateCustomer.run(
            social_customer: social_customer,
            customer_last_name: profile.last_name || "",
            customer_first_name: profile.first_name || "",
            customer_phonetic_last_name: profile.phonetic_last_name,
            customer_phonetic_first_name: profile.phonetic_first_name,
            customer_phone_number: profile.phone_number || ""
          )
          if foc_outcome.invalid?
            Rails.logger.warn("[LineVerification] FindOrCreateCustomer failed: social_customer_id=#{social_customer.id}, errors=#{foc_outcome.errors.full_messages.join(', ')}")
          end
        else
          social_customer.update_columns(is_owner: false)
          Rails.logger.warn("[LineVerification] Flex send failed: social_customer_id=#{social_customer.id}, uid=#{social_customer.social_user_id}, errors=#{outcome.errors.full_messages.join(', ')}")
        end
      end

      if all_requests_result.empty? || all_requests_result.all?(false)
        Rails.logger.error("[LineVerification] All Flex sends failed: user_id=#{current_user.id}, social_account_id=#{target_social_account.id}, candidates=#{all_requests_result.size}")
        Notifiers::Users::LineSettings::VerifyFailedMessage.run(receiver: current_user.social_user)
        Notifiers::Users::LineSettings::VerifyFailedVideo.run(receiver: current_user.social_user)
      end
    end

    if current_user.social_account&.line_settings_verified?
      SocialAccounts::RichMenus::CustomerReservations.run(social_account: current_user.social_account)
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

  # Same social_account に属する全 social_customer を候補にする。
  # LINE Login UID と Messaging API UID が異なるケースでは、
  # webhook (follow/message) 経由で作られた social_customer が正しい UID を持つ。
  # social_user_name マッチだと、名前変更・非同期プロファイル取得遅延で漏れるため
  # social_account_id ベースで候補を広げる。
  def verification_candidates(target_social_account)
    current_user.social_customers.where(social_account_id: target_social_account.id)
  end

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

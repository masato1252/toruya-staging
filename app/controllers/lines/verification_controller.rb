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

      verification_candidates(target_social_account).each do |social_customer|
        uid_reachable = messaging_api_uid_reachable?(target_social_account, social_customer.social_user_id)

        unless uid_reachable
          Rails.logger.warn("[LineVerification] UID unreachable via Messaging API: social_customer_id=#{social_customer.id}, uid=#{social_customer.social_user_id}, social_account_id=#{target_social_account.id}")
          all_requests_result << false
          social_customer.update_columns(is_owner: false)
          next
        end

        outcome = Notifiers::Customers::LineSettings::LineLoginVerificationFlex.run(receiver: social_customer)
        sent_ok = outcome.valid?
        all_requests_result << sent_ok

        Rails.logger.info("[LineVerification] Flex send: social_customer_id=#{social_customer.id}, uid=#{social_customer.social_user_id}, social_account_id=#{target_social_account.id}, success=#{sent_ok}")
        Rollbar.info("[LineVerification] Flex send result", social_customer_id: social_customer.id, uid: social_customer.social_user_id, social_account_id: target_social_account.id, success: sent_ok) unless sent_ok

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
        end
      end

      if all_requests_result.empty? || all_requests_result.all?(false)
        Rails.logger.error("[LineVerification] All Flex sends failed: user_id=#{current_user.id}, social_account_id=#{target_social_account.id}, candidates=#{all_requests_result.size}")
        Notifiers::Users::LineSettings::VerifyFailedMessage.run(receiver: current_user.social_user)
        Notifiers::Users::LineSettings::VerifyFailedVideo.run(receiver: current_user.social_user)
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

  # Same social_account に属する全 social_customer を候補にする。
  # LINE Login UID と Messaging API UID が異なるケースでは、
  # webhook (follow/message) 経由で作られた social_customer が正しい UID を持つ。
  # social_user_name マッチだと、名前変更・非同期プロファイル取得遅延で漏れるため
  # social_account_id ベースで候補を広げる。
  def verification_candidates(target_social_account)
    current_user.social_customers.where(social_account_id: target_social_account.id)
  end

  # Messaging API の get_profile で UID が到達可能か（友だち追加済みか）を事前チェック。
  # push_message 失敗を Flex 送信前に検知して無駄な SocialMessage レコード作成を防ぐ。
  def messaging_api_uid_reachable?(social_account, uid)
    return false if uid.blank? || social_account.client.nil?

    response = social_account.client.get_profile(uid)
    response.is_a?(Net::HTTPSuccess)
  rescue => e
    Rails.logger.warn("[LineVerification] get_profile failed: uid=#{uid}, error=#{e.class} #{e.message}")
    false
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

# frozen_string_literal: true

class CallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :verify_authenticity_token
  BUSINESS_LOGIN = "business_login"
  TORUYA_USER = "toruya_user"
  TW_TORUYA_USER = "tw_toruya_user"
  SHOP_OWNER_CUSTOMER_SELF = "shop_owner_customer_self"

  include Devise::Controllers::Rememberable
  include UserBotCookies

  def google_oauth2
    param = request.env["omniauth.params"]
    outcome = ::Users::FromOmniauth.run(
      auth: request.env["omniauth.auth"],
      referral_token: param["referral_token"],
      social_service_user_id: param["social_service_user_id"]
    )

    if outcome.valid?
      user = outcome.result
      remember_me(user)
      sign_in(user)

      if param[BUSINESS_LOGIN]
        redirect_to business_path
      elsif param["social_service_user_id"]
        redirect_to lines_user_bot_connect_user_path(param["social_service_user_id"])
      else
        redirect_to user.profile ? member_path : new_profile_path
      end
    else
      redirect_to new_user_registration_url
    end
  end

  def stripe_connect
    current_user = User.find_by(id: ENV["DEV_USER_ID"] || user_bot_cookies(:current_user_id))
    param = request.env["omniauth.params"]

    outcome = Users::FromProviderOmniauth.run(
      user: current_user,
      auth: request.env["omniauth.auth"],
      provider: AccessProvider.providers[:stripe_connect]
    )

    uri = URI.parse(param['oauth_redirect_to_url'])
    queries = URI.decode_www_form(uri.query || "") << ["status", outcome.valid?]
    uri.query = URI.encode_www_form(queries)

    flash[:success] = I18n.t("common.update_successfully_message")
    redirect_to uri.to_s
  end

  def square
    current_user = User.find_by(id: ENV["DEV_USER_ID"] || user_bot_cookies(:current_user_id))
    param = request.env["omniauth.params"]

    outcome = Users::FromProviderOmniauth.run(
      user: current_user,
      auth: request.env["omniauth.auth"],
      provider: AccessProvider.providers[:square]
    )

    uri = URI.parse(param['oauth_redirect_to_url'])
    queries = URI.decode_www_form(uri.query || "") << ["status", outcome.valid?]
    uri.query = URI.encode_www_form(queries)

    flash[:success] = I18n.t("common.update_successfully_message")
    redirect_to uri.to_s
  end

  def line
    param = request.env["omniauth.params"]

    Rollbar.info("LineLogin1", who: param["who"] ? MessageEncryptor.decrypt(param["who"]) : nil, oauth_redirect_to_url: param["oauth_redirect_to_url"])

    if param["who"] && (MessageEncryptor.decrypt(param["who"]) == TORUYA_USER || MessageEncryptor.decrypt(param["who"]) == TW_TORUYA_USER)
      outcome = ::SocialUsers::FromOmniauth.run(
        auth: request.env["omniauth.auth"],
        who: MessageEncryptor.decrypt(param["who"])
      )
      social_user = outcome.result
      # if param["existing_owner_id"]
      #   1.2 user login for add another line account
      # elsif param["staff_token"]
      #   1.1 user login be other staff
      # else
      #   user login

      if outcome.valid? && social_user&.user
        # line sign in
        user = social_user.user
        
        Rollbar.info("LineLoginSuccess", 
          user_id: user.id, 
          social_user_id: social_user.id,
          social_service_user_id: social_user.social_service_user_id
        )
        
        remember_me(user)
        sign_in(user)
        write_user_bot_cookies(:social_service_user_id, social_user.social_service_user_id)
        write_user_bot_cookies(:current_user_id, user.id)

        if param["existing_owner_id"] # existing user add another line account
          existing_user = User.find(param["existing_owner_id"])

          if existing_user.social_user.social_service_user_id == social_user.social_service_user_id
            new_user = Users::NewAccount.run!(existing_user: existing_user)

            write_user_bot_cookies(:current_user_id, new_user.id)
            remember_me(new_user)
            sign_in(new_user)

            redirect_to lines_user_bot_settings_path(new_user.id), notice: I18n.t("new_line_account.successful_message")
          else
            Rollbar.error("NewAccountCreationFailure", existing_user_id: existing_user.id, existing_social_user_id: existing_user.social_user.id, social_user_id: social_user.id, auth_info: request.env["omniauth.auth"].info)

            redirect_to lines_user_bot_settings_path(user.id), alert: I18n.t("common.update_failed_message")
          end
        elsif param["staff_token"]
          staff_connect_outcome = StaffAccounts::ConnectUser.run(token: param["staff_token"], user: user)

          if staff_connect_outcome.valid?
            redirect_to lines_user_bot_settings_path(staff_connect_outcome.result.owner_id, staff_connect_result: staff_connect_outcome.valid?)
          else
            redirect_to lines_user_bot_settings_path(user.id, staff_connect_result: staff_connect_outcome.valid?)
          end
        elsif param["consultant_token"]
          consultant_connect_outcome = StaffAccounts::CreateConsultant.run(token: param["consultant_token"], client: user)

          redirect_to lines_user_bot_settings_path(user.id, consultant_connect_result: consultant_connect_outcome.valid?)
        else
          Rollbar.info("LineLogin", user_id: user.id, oauth_redirect_to_url: param["oauth_redirect_to_url"])
          
          # oauth_redirect_to_url could be root_path ("/"), which requires authentication
          # Redirect to schedules page if no specific redirect URL is provided or if it's root_path
          redirect_url = param["oauth_redirect_to_url"]
          if redirect_url.blank? || redirect_url == "/" || redirect_url == root_path
            redirect_to lines_user_bot_schedules_path(business_owner_id: user.id)
          else
            redirect_to Addressable::URI.new(path: redirect_url).to_s
          end
        end
      elsif outcome.valid? && outcome.result.user.nil?
        # user sign up
        redirect_to lines_user_bot_sign_up_path(outcome.result.social_service_user_id, staff_token: param["staff_token"], consultant_token: param["consultant_token"], locale: param["locale"])
      else
        redirect_to root_path
      end
    else
      Rollbar.info("LineLogin2", who: param["who"] ? MessageEncryptor.decrypt(param["who"]) : nil, oauth_redirect_to_url: param["oauth_redirect_to_url"])

      # CallbackフェーズではパラメータがSessionに保存されているので復元
      param["oauth_social_account_id"] ||= session[:oauth_social_account_id]
      param["who"] ||= session[:line_oauth_who]
      
      # 予約情報もSessionから復元
      %w[booking_option_ids booking_date booking_at staff_id].each do |key|
        param[key] ||= session["oauth_#{key}"]
      end
      
      Rails.logger.info("[CallbacksController] Callback phase - param keys: #{param.keys.join(', ')}")
      Rails.logger.info("[CallbacksController]   oauth_social_account_id: #{param["oauth_social_account_id"].present? ? 'present' : 'nil'}")
      Rails.logger.info("[CallbacksController]   who: #{param["who"].present? ? 'present' : 'nil'}")

      outcome = ::SocialCustomers::FromOmniauth.run(
        auth: request.env["omniauth.auth"],
        param: param,
        who: param["who"] && MessageEncryptor.decrypt(param["who"])
      )
      
      Rails.logger.info("[CallbacksController] SocialCustomers::FromOmniauth result:")
      Rails.logger.info("[CallbacksController]   outcome.valid?: #{outcome.valid?}")
      if outcome.valid?
        Rails.logger.info("[CallbacksController]   social_customer_id: #{outcome.result.id}")
        Rails.logger.info("[CallbacksController]   social_user_id: #{outcome.result.social_user_id}")
        Rails.logger.info("[CallbacksController]   customer_id: #{outcome.result.customer_id}")
      else
        Rails.logger.error("[CallbacksController]   errors: #{outcome.errors.full_messages.join(', ')}")
      end

      param.delete("bot_prompt")
      param.delete("prompt")
      oauth_redirect_to_url = param.delete("oauth_redirect_to_url") || session[:oauth_redirect_to_url]

      # oauth_redirect_to_urlがnilの場合はroot_pathにリダイレクト
      if oauth_redirect_to_url.blank?
        Rails.logger.warn("[CallbacksController] oauth_redirect_to_url is blank, redirecting to root")
        redirect_to root_path
        return
      end
      
      # Sessionから取得した場合はクリア
      session.delete(:oauth_redirect_to_url) if session[:oauth_redirect_to_url].present?
      session.delete(:oauth_social_account_id) if session[:oauth_social_account_id].present?
      session.delete(:line_oauth_who) if session[:line_oauth_who].present?
      session.delete(:line_oauth_credentials) if session[:line_oauth_credentials].present?
      
      # 予約情報もクリア
      %w[booking_option_ids booking_date booking_at staff_id].each do |key|
        session.delete("oauth_#{key}") if session["oauth_#{key}"].present?
      end
      
      Rails.logger.info("[CallbacksController] Sessionクリア完了")

      uri = URI.parse(oauth_redirect_to_url)
      
      # デバッグ: paramの内容を確認
      Rails.logger.info("[CallbacksController] リダイレクト前のparam: #{param.keys.join(', ')}")
      Rails.logger.info("[CallbacksController]   booking_option_ids: #{param['booking_option_ids'].inspect}")
      Rails.logger.info("[CallbacksController]   booking_date: #{param['booking_date'].inspect}")
      Rails.logger.info("[CallbacksController]   booking_at: #{param['booking_at'].inspect}")
      Rails.logger.info("[CallbacksController]   staff_id: #{param['staff_id'].inspect}")
      Rails.logger.info("[CallbacksController] oauth_redirect_to_url: #{oauth_redirect_to_url}")
      
      queries = {
        status: outcome.valid?,
        social_user_id: outcome.result.social_user_id
      }.merge(param, Rack::Utils.parse_nested_query(uri.query || {}))

      uri.query = URI.encode_www_form(queries)

      if outcome.result.social_user_id.present?
        cookies.clear_across_domains(:line_social_user_id_of_customer)
        cookies.set_across_domains(:line_social_user_id_of_customer, outcome.result.social_user_id, expires: 20.years.from_now)
        
        # LINEから取得したemailをCookieに保存（1時間有効）
        if outcome.respond_to?(:compositions) && outcome.compositions[:line_email].present?
          cookies.set_across_domains(:line_customer_email, outcome.compositions[:line_email], expires: 1.hour.from_now)
        end
      end

      redirect_to uri.to_s
    end
  end
end

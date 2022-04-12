# frozen_string_literal: true

class CallbacksController < Devise::OmniauthCallbacksController
  BUSINESS_LOGIN = "business_login"
  TORUYA_USER = "toruya_user"

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

    outcome = Users::FromStripeOmniauth.run(
      user: current_user,
      auth: request.env["omniauth.auth"]
    )

    uri = URI.parse(param['oauth_redirect_to_url'])
    queries = URI.decode_www_form(uri.query || "") << ["status", outcome.valid?]
    uri.query = URI.encode_www_form(queries)

    redirect_to uri.to_s
  end

  def line
    param = request.env["omniauth.params"]

    if param["who"] && MessageEncryptor.decrypt(param["who"]) == TORUYA_USER
      outcome = ::SocialUsers::FromOmniauth.run(
        auth: request.env["omniauth.auth"],
      )

      if outcome.valid? && outcome.result&.user
        user = outcome.result.user
        remember_me(user)
        sign_in(user)

        redirect_to admin_chats_path
      else
        redirect_to root_path
      end
    else
      outcome = ::SocialCustomers::FromOmniauth.run(
        auth: request.env["omniauth.auth"],
        param: param,
      )

      param.delete("bot_prompt")
      param.delete("prompt")
      oauth_redirect_to_url = param.delete("oauth_redirect_to_url")

      uri = URI.parse(oauth_redirect_to_url)
      queries = {
        status: outcome.valid?,
        social_user_id: outcome.result.social_user_id
      }.merge(param)
      uri.query = URI.encode_www_form(queries)

      if outcome.result.social_user_id.present?
        cookies.permanent[:line_social_user_id_of_customer] = outcome.result.social_user_id
      end

      redirect_to uri.to_s
    end
  end
end

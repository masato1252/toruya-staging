# frozen_string_literal: true

class CallbacksController < Devise::OmniauthCallbacksController
  BUSINESS_LOGIN = "business_login"
  TORUYA_USER = "toruya_user"
  SHOP_OWNER_CUSTOMER_SELF = "shop_owner_customer_self"
  TORUYA_USER_LINE_SIGN_UP = "toruya_user_line_sign_up"

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
        # line sign in
        user = outcome.result.user
        remember_me(user)
        sign_in(user)
        write_user_bot_cookies(:current_user_id, user.id)

        if param["staff_token"]
          staff_connect_outcome = StaffAccounts::ConnectUser.run(token: param["staff_token"], user: user)

          redirect_to lines_user_bot_schedules_path(staff_connect_result: staff_connect_outcome.valid?)
        else
          redirect_to Addressable::URI.new(path: param.delete("oauth_redirect_to_url")).to_s
        end
      elsif outcome.valid? && outcome.result.user.nil?
        # line sign up
        redirect_to lines_user_bot_sign_up_path(outcome.result.social_service_user_id, staff_token: param["staff_token"])
      else
        redirect_to root_path
      end
    else
      outcome = ::SocialCustomers::FromOmniauth.run(
        auth: request.env["omniauth.auth"],
        param: param,
        who: param["who"] && MessageEncryptor.decrypt(param["who"])
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

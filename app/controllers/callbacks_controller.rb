class CallbacksController < Devise::OmniauthCallbacksController
  BUSINESS_LOGIN = "business_login"

  include Devise::Controllers::Rememberable

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

  def line
    param = request.env["omniauth.params"]

    outcome = ::SocialCustomers::FromOmniauth.run(
      auth: request.env["omniauth.auth"],
      param: param,
    )

    uri = URI.parse(param['oauth_redirect_to_url'])
    queries = {
      status: outcome.valid?,
      social_user_id: outcome.result.social_user_id
    }
    uri.query = URI.encode_www_form(queries)

    redirect_to uri.to_s
  end
end

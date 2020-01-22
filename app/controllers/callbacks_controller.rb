class CallbacksController < Devise::OmniauthCallbacksController
  BUSINESS_LOGIN = "business_login"

  include Devise::Controllers::Rememberable

  def google_oauth2
    param = request.env["omniauth.params"]
    outcome = ::Users::FromOmniauth.run(auth: request.env["omniauth.auth"], referral_token: param["referral_token"])

    if outcome.valid?
      user = outcome.result
      remember_me(user)
      sign_in(user)

      if param[BUSINESS_LOGIN]
        redirect_to business_path
      else
        redirect_to user.profile ? member_path : new_profile_path
      end
    else
      redirect_to new_user_registration_url
    end
  end
end

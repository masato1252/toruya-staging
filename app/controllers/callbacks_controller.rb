class CallbacksController < Devise::OmniauthCallbacksController
  include Devise::Controllers::Rememberable

  def google_oauth2
    outcome = ::Users::FromOmniauth.run(auth: request.env["omniauth.auth"])

    if outcome.valid?
      user = outcome.result
      remember_me(user)
      sign_in(user)

      redirect_to member_path
    else
      redirect_to new_user_registration_url
    end
  end
end

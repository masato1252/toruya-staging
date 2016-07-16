class CallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    outcome = CreateGoogleOauth.run(user: current_user, auth: request.env["omniauth.auth"])

    if outcome.valid?
      redirect_to root_path
    else
      redirect_to root_path, notice: 'Access Denied.'
    end
  end
end

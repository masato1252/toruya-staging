class CallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    outcome = GoogleOauth::Create.run(user: current_user, auth: request.env["omniauth.auth"])

    if outcome.valid?
      redirect_to settings_contact_groups_path
    else
      redirect_to settings_contact_groups_path, notice: 'Access Denied.'
    end
  end
end

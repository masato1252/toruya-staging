class CallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    outcome = GoogleOauth::Create.run(user: current_user, auth: request.env["omniauth.auth"])

    if outcome.valid?
      redirect_to settings_user_contact_groups_path(super_user)
    else
      redirect_to settings_user_contact_groups_path(super_user), notice: 'Access Denied.'
    end
  end
end

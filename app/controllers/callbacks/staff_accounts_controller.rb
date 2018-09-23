class Callbacks::StaffAccountsController < ActionController::Base
  include Devise::Controllers::Rememberable

  def create
    outcome = StaffAccounts::CreateUser.run(token: params[:token])

    result = outcome.result
    if outcome.valid?
      user = result[:user]
      owner = result[:owner]

      if outcome.result[:reset_password_token]
        # New User
        # Don't sign in for new user we need users walkthrough google login flow.
        sign_out
        reset_session

        # uncomment this if we need to take password page back
        # session[:super_user_id_from_staff_account] = owner.id

        redirect_to new_settings_user_profile_path(user, from_staff_account: true), notice: "Set up your account"
      else
        # existing user
        redirect_back(fallback_location: member_path, notice: I18n.t("settings.staff_account.connected_your_account"))
      end
    else
      redirect_to member_path, alert: outcome.errors.full_messages.first
    end
  end
end

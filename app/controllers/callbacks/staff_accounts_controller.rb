class Callbacks::StaffAccountsController < ActionController::Base
  def create
    outcome = StaffAccounts::CreateUser.run(token: params[:token])

    if outcome.valid?
      if outcome.result[:reset_password_token]
        sign_out
        reset_session
        session[:super_user_id_from_staff_account] = outcome.result[:owner].id
        redirect_to sign_in_path
      else
        redirect_back(fallback_location: settings_path(current_user), notice: "Connected your staff account.")
      end
    else
      redirect_to member_path, alert: outcome.errors.full_messages.first
    end
  end
end

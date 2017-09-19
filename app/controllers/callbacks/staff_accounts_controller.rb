class Callbacks::StaffAccountsController < ActionController::Base
  def create
    outcome = StaffAccounts::CreateUser.run(token: params[:token])

    if outcome.valid?
      if outcome.result[:reset_password_token]
        sign_out
        reset_session
        session[:super_user_id_from_staff_account] = outcome.result[:owner].id
        redirect_to edit_password_path(outcome.result[:user], reset_password_token: outcome.result[:reset_password_token])
      else
        redirect_to root_path, notice: "Connected your staff account."
      end
    else
      redirect_to root_path, alert: outcome.errors.full_messages.first
    end
  end
end

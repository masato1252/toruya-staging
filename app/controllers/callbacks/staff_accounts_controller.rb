class Callbacks::StaffAccountsController < ActionController::Base
  def create
    sign_out
    reset_session

    outcome = StaffAccounts::CreateUser.run(token: params[:token])

    if outcome.valid?
      redirect_to edit_password_path(outcome.result[:user], reset_password_token: outcome.result[:reset_password_token])
    else
      redirect_to root_path, alert: outcome.errors.full_messages.first
    end
  end
end

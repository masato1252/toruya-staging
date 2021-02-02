# frozen_string_literal: true

class Callbacks::StaffAccountsController < ActionController::Base
  include Devise::Controllers::Rememberable

  def create
    outcome = StaffAccounts::CreateUser.run(token: params[:token])
    sign_out
    reset_session

    if outcome.valid?
      session[:create_from_staff_account] = true
      redirect_to new_user_session_path, notice: I18n.t("settings.staff_account.connected_your_account")
    else
      redirect_to new_user_session_path, alert: outcome.errors.full_messages.first
    end
  end
end

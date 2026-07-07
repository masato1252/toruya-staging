# frozen_string_literal: true

class OwnerAuthController < ActionController::Base
  include ControllerHelpers
  include LineAuthGateway

  def authorize
    apply_intent_params!(default_purpose: "owner_settings")
    purpose = params[:purpose].presence || "owner_settings"
    return redirect_to root_path, alert: "不正なログイン要求です" unless %w[owner_settings owner_signup].include?(purpose)

    clear_line_oauth_state!

    toruya_user = params[:locale] == "tw" ? CallbacksController::TW_TORUYA_USER : CallbacksController::TORUYA_USER
    encrypted_who = MessageEncryptor.encrypt(toruya_user)

    session[:line_auth_pending] = {
      "purpose" => purpose,
      "return_to" => params[:return_to],
      "staff_token" => params[:staff_token],
      "consultant_token" => params[:consultant_token],
      "existing_owner_id" => params[:existing_owner_id],
      "locale" => params[:locale]
    }.compact

    set_toruya_line_oauth_credentials!(locale: params[:locale])
    session[:line_oauth_who_routing] = encrypted_who

    render_line_omniauth_auto_post(
      form_id: "owner_auth_form",
      hidden_fields: {
        whois: encrypted_who,
        who: encrypted_who,
        oauth_redirect_to_url: params[:return_to],
        staff_token: params[:staff_token],
        consultant_token: params[:consultant_token],
        existing_owner_id: params[:existing_owner_id],
        locale: params[:locale],
        prompt: "consent",
        bot_prompt: "aggressive"
      }
    )
  end
end

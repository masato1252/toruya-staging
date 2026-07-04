# frozen_string_literal: true

class OwnerAuthController < ActionController::Base
  include ControllerHelpers
  include LineAuthGateway

  def authorize
    merged = merge_intent_params!({
      "return_to" => params[:return_to],
      "staff_token" => params[:staff_token],
      "consultant_token" => params[:consultant_token],
      "existing_owner_id" => params[:existing_owner_id],
      "locale" => params[:locale].presence,
      "purpose" => params[:purpose].presence || infer_owner_purpose
    })
    return if merged.nil?

    locale = merged["locale"].presence || "ja"
    toruya_user = toruya_user_constant(locale)
    encrypted_whois = MessageEncryptor.encrypt(toruya_user)
    return_to = merged["return_to"].presence

    clear_line_oauth_state!

    purpose = merged["purpose"].presence || "owner_settings"
    session[:line_oauth_credentials] = toruya_line_credentials(locale)
    session[:oauth_redirect_to_url] = return_to if return_to.present?

    store_line_auth_pending!(
      purpose: purpose,
      return_to: return_to,
      staff_token: merged["staff_token"],
      consultant_token: merged["consultant_token"],
      existing_owner_id: merged["existing_owner_id"],
      locale: locale
    )

    render_line_oauth_post_form(
      form_id: "owner_auth_form",
      hidden_fields: {
        whois: encrypted_whois,
        who: encrypted_whois,
        oauth_redirect_to_url: return_to,
        staff_token: merged["staff_token"],
        consultant_token: merged["consultant_token"],
        existing_owner_id: merged["existing_owner_id"],
        locale: locale,
        prompt: "consent",
        bot_prompt: "aggressive"
      }
    )
  end

  private

  def infer_owner_purpose
    return_to = params[:return_to].to_s
    return "owner_signup" if return_to.include?("sign_up")
    "owner_settings"
  end
end

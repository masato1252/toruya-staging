# frozen_string_literal: true

class ShopAuthController < ActionController::Base
  include ControllerHelpers
  include LineAuthGateway

  def authorize
    apply_intent_params!(default_purpose: "shop_customer")

    encrypted_account_id = params[:social_account_id].presence || params[:oauth_social_account_id]
    return redirect_to root_path, alert: "店舗が指定されていません" if encrypted_account_id.blank?

    account = SocialAccount.find(MessageEncryptor.decrypt(encrypted_account_id))
    return redirect_to root_path, alert: "LINEログインが利用できません" unless account.is_login_available?

    purpose = if params[:who].present?
                "shop_owner_customer_self"
              else
                params[:purpose].presence || "shop_customer"
              end

    clear_line_oauth_state!
    store_booking_oauth_params_in_session!

    session[:line_auth_pending] = {
      "purpose" => purpose,
      "return_to" => params[:return_to],
      "oauth_social_account_id" => encrypted_account_id,
      "who" => params[:who]
    }.compact

    set_shop_line_oauth_credentials!(account)
    session[:oauth_social_account_id] = encrypted_account_id
    session[:oauth_redirect_to_url] = params[:return_to] if params[:return_to].present?

    who_routing = params[:who]
    session[:line_oauth_who_routing] = who_routing if who_routing.present?

    render_line_omniauth_auto_post(
      form_id: "shop_auth_form",
      hidden_fields: {
        oauth_social_account_id: encrypted_account_id,
        oauth_redirect_to_url: params[:return_to],
        who: who_routing,
        customer_id: params[:customer_id],
        booking_option_ids: params[:booking_option_ids],
        booking_date: params[:booking_date],
        booking_at: params[:booking_at],
        staff_id: params[:staff_id],
        prompt: "consent",
        bot_prompt: "aggressive"
      }
    )
  rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "店舗が見つかりません"
  end
end

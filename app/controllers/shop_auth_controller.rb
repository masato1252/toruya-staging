# frozen_string_literal: true

class ShopAuthController < ActionController::Base
  include ControllerHelpers
  include LineAuthGateway

  def authorize
    merged = merge_intent_params!({
      "return_to" => params[:return_to],
      "social_account_id" => params[:social_account_id],
      "who" => params[:who],
      "customer_id" => params[:customer_id],
      "booking_option_ids" => params[:booking_option_ids],
      "booking_date" => params[:booking_date],
      "booking_at" => params[:booking_at],
      "staff_id" => params[:staff_id]
    })
    return if merged.nil?

    encrypted_account_id = merged["social_account_id"].presence
    if encrypted_account_id.blank?
      return redirect_to root_path, alert: "店舗情報が指定されていません"
    end

    begin
      account = SocialAccount.find(MessageEncryptor.decrypt(encrypted_account_id))
    rescue StandardError
      return redirect_to root_path, alert: "店舗情報が見つかりません"
    end

    unless account.is_login_available?
      return redirect_to root_path, alert: "LINE ログインは利用できません"
    end

    who_encrypted = merged["who"].presence
    purpose =
      if who_encrypted.present? && MessageEncryptor.decrypt(who_encrypted) == CallbacksController::SHOP_OWNER_CUSTOMER_SELF
        "shop_owner_customer_self"
      else
        "shop_customer"
      end

    return_to = merged["return_to"].presence

    clear_line_oauth_state!

    session[:line_oauth_credentials] = {
      client_id: account.login_channel_id,
      client_secret: account.raw_login_channel_secret
    }
    session[:oauth_social_account_id] = encrypted_account_id
    session[:oauth_redirect_to_url] = return_to if return_to.present?
    session[:line_oauth_who_routing] = who_encrypted if who_encrypted.present?

    booking_data = {}
    LineAuthGateway::OAUTH_BOOKING_KEYS.each do |key|
      value = merged[key]
      next if value.blank?

      session["oauth_#{key}"] = value
      booking_data[key] = value
    end

    store_line_auth_pending!(
      {
        purpose: purpose,
        return_to: return_to,
        social_account_id: encrypted_account_id,
        who: who_encrypted
      }.merge(booking_data)
    )

    render_line_oauth_post_form(
      form_id: "shop_auth_form",
      hidden_fields: {
        oauth_social_account_id: encrypted_account_id,
        oauth_redirect_to_url: return_to,
        who: who_encrypted,
        customer_id: merged["customer_id"],
        booking_option_ids: merged["booking_option_ids"],
        booking_date: merged["booking_date"],
        booking_at: merged["booking_at"],
        staff_id: merged["staff_id"],
        prompt: "consent",
        bot_prompt: "aggressive"
      }
    )
  end
end

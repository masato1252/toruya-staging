# frozen_string_literal: true

module LineAuthGateway
  extend ActiveSupport::Concern

  OAUTH_SESSION_KEYS = %i[
    line_oauth_credentials line_oauth_who line_oauth_who_routing
    oauth_redirect_to_url oauth_social_account_id
  ].freeze

  OAUTH_BOOKING_KEYS = %w[booking_option_ids booking_date booking_at staff_id customer_id].freeze

  private

  def clear_line_oauth_state!
    OAUTH_SESSION_KEYS.each { |key| session.delete(key) }
    OAUTH_BOOKING_KEYS.each { |key| session.delete("oauth_#{key}") }
    cookies.clear_across_domains(:whois, :who, :oauth_social_account_id, :oauth_redirect_to_url)
  end

  def apply_intent_params!(default_purpose:)
    return unless params[:intent_token].present?

    intent = LineLoginIntent.verify!(params[:intent_token])
    params[:purpose] ||= intent[:purpose] || default_purpose
    params[:return_to] ||= intent[:return_to]
    params[:social_account_id] ||= intent[:social_account_id]&.then { |id| MessageEncryptor.encrypt(id) }
    params[:event_slug] ||= intent[:event_slug]
    params[:doc_slug] ||= intent[:doc_slug]
    params[:staff_token] ||= intent[:staff_token]
    params[:consultant_token] ||= intent[:consultant_token]
    params[:locale] ||= intent[:locale]
    params[:who] ||= intent[:who]
  end

  def set_toruya_line_oauth_credentials!(locale: nil)
    locale = locale.presence || params[:locale].presence || "ja"
    secrets = Rails.application.secrets[locale.to_sym == "tw" ? :tw : :ja]
    session[:line_oauth_credentials] = {
      client_id: secrets[:toruya_line_login_id],
      client_secret: secrets[:toruya_line_login_secret]
    }
  end

  def set_shop_line_oauth_credentials!(social_account)
    session[:line_oauth_credentials] = {
      client_id: social_account.login_channel_id,
      client_secret: social_account.raw_login_channel_secret
    }
  end

  def store_booking_oauth_params_in_session!
    OAUTH_BOOKING_KEYS.each do |key|
      session["oauth_#{key}"] = params[key] if params[key].present?
    end
  end

  def render_line_omniauth_auto_post(form_id:, hidden_fields:)
    @form_action = user_line_omniauth_authorize_path
    @csrf_token = form_authenticity_token
    @hidden_fields = hidden_fields
    @form_id = form_id

    render inline: <<~HTML, layout: false
      <!DOCTYPE html>
      <html>
      <head><meta charset="utf-8"><title>LINE ログイン</title></head>
      <body>
        <form id="<%= @form_id %>" method="post" action="<%= @form_action %>">
          <input type="hidden" name="authenticity_token" value="<%= @csrf_token %>" />
          <% @hidden_fields.each do |name, value| %>
            <% next if value.blank? %>
            <input type="hidden" name="<%= name %>" value="<%= value %>" />
          <% end %>
        </form>
        <script>document.getElementById("<%= @form_id %>").submit();</script>
      </body>
      </html>
    HTML
  end

  def user_line_omniauth_authorize_path
    Rails.application.routes.url_helpers.user_line_omniauth_authorize_path
  end
end

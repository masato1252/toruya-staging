# frozen_string_literal: true

module LineAuthGateway
  extend ActiveSupport::Concern

  OAUTH_SESSION_KEYS = %i[
    line_oauth_credentials line_oauth_who line_oauth_who_routing
    oauth_redirect_to_url oauth_social_account_id line_auth_pending
  ].freeze

  OAUTH_BOOKING_KEYS = %w[booking_option_ids booking_date booking_at staff_id customer_id].freeze

  private

  def clear_line_oauth_state!
    OAUTH_SESSION_KEYS.each { |key| session.delete(key) }
    OAUTH_BOOKING_KEYS.each { |key| session.delete("oauth_#{key}") }
    cookies.clear_across_domains(:whois, :who, :oauth_social_account_id, :oauth_redirect_to_url)
  end

  def merge_intent_params!(base_params)
    token = params[:intent_token].presence
    return base_params if token.blank?

    intent = LineLoginIntent.verify!(token)
    base_params.merge(intent.compact)
  rescue LineLoginIntent::VerificationError => e
    Rails.logger.warn("[LineAuthGateway] Invalid intent token: #{e.message}")
    redirect_to root_path, alert: "ログインリンクの有効期限が切れています。もう一度お試しください。"
    nil
  end

  def store_line_auth_pending!(pending)
    session[:line_auth_pending] = pending.stringify_keys
  end

  def render_line_oauth_post_form(form_id:, hidden_fields:)
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

  def toruya_line_credentials(locale)
    if locale.to_s == "tw"
      {
        client_id: Rails.application.secrets[:tw][:toruya_line_login_id],
        client_secret: Rails.application.secrets[:tw][:toruya_line_login_secret]
      }
    else
      {
        client_id: Rails.application.secrets[:ja][:toruya_line_login_id],
        client_secret: Rails.application.secrets[:ja][:toruya_line_login_secret]
      }
    end
  end

  def toruya_user_constant(locale)
    locale.to_s == "tw" ? CallbacksController::TW_TORUYA_USER : CallbacksController::TORUYA_USER
  end
end

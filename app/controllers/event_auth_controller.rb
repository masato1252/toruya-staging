# frozen_string_literal: true

class EventAuthController < ActionController::Base
  include ControllerHelpers

  def authorize
    event_slug = params[:event_slug]
    return redirect_to root_path, alert: "イベントが指定されていません" if event_slug.blank?

    event = Event.published.undeleted.find_by(slug: event_slug)
    return redirect_to root_path, alert: "イベントが見つかりません" unless event

    # 全 OAuth 関連セッション/Cookie を徹底クリア
    %i[
      line_oauth_credentials line_oauth_who line_oauth_who_routing
      oauth_redirect_to_url oauth_social_account_id
    ].each { |key| session.delete(key) }
    %w[booking_option_ids booking_date booking_at staff_id customer_id].each do |key|
      session.delete("oauth_#{key}")
    end
    cookies.clear_across_domains(:whois, :who, :oauth_social_account_id, :oauth_redirect_to_url)

    # イベント専用フラグをセッションに設定
    session[:event_auth_pending] = {
      "event_slug" => event_slug,
      "return_to" => params[:return_to]
    }

    # OmniAuth 用のセッション値を設定
    encrypted_who = MessageEncryptor.encrypt(CallbacksController::EVENT_LINE_USER)
    encrypted_whois = MessageEncryptor.encrypt(CallbacksController::TORUYA_USER)

    session[:line_oauth_credentials] = {
      client_id: Rails.application.secrets[:ja][:toruya_line_login_id],
      client_secret: Rails.application.secrets[:ja][:toruya_line_login_secret]
    }
    session[:line_oauth_who_routing] = encrypted_who

    oauth_redirect_to_url = new_event_participation_path(event_slug: event_slug)
    session[:oauth_redirect_to_url] = oauth_redirect_to_url

    # 自動送信 POST フォームを返す
    @form_action = user_line_omniauth_authorize_path
    @csrf_token = form_authenticity_token
    @hidden_fields = {
      whois: encrypted_whois,
      who: encrypted_who,
      oauth_redirect_to_url: oauth_redirect_to_url,
      prompt: "consent",
      bot_prompt: "aggressive"
    }

    render inline: <<~HTML, layout: false
      <!DOCTYPE html>
      <html>
      <head><meta charset="utf-8"><title>LINE ログイン</title></head>
      <body>
        <form id="event_auth_form" method="post" action="<%= @form_action %>">
          <input type="hidden" name="authenticity_token" value="<%= @csrf_token %>" />
          <% @hidden_fields.each do |name, value| %>
            <input type="hidden" name="<%= name %>" value="<%= value %>" />
          <% end %>
        </form>
        <script>document.getElementById("event_auth_form").submit();</script>
      </body>
      </html>
    HTML
  end

  private

  def user_line_omniauth_authorize_path
    Rails.application.routes.url_helpers.user_line_omniauth_authorize_path
  end

  def new_event_participation_path(event_slug:)
    Rails.application.routes.url_helpers.new_event_participation_path(event_slug: event_slug)
  end
end

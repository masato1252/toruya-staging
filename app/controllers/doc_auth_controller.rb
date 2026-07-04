# frozen_string_literal: true

class DocAuthController < ActionController::Base
  include ControllerHelpers

  def authorize
    doc_slug = params[:doc_slug]
    return redirect_to root_path, alert: "資料が指定されていません" if doc_slug.blank?

    doc = Doc.status_published.active.find_by(slug: doc_slug)
    return redirect_to root_path, alert: "資料が見つかりません" unless doc

    %i[
      line_oauth_credentials line_oauth_who line_oauth_who_routing
      oauth_redirect_to_url oauth_social_account_id
    ].each { |key| session.delete(key) }
    %w[booking_option_ids booking_date booking_at staff_id customer_id].each do |key|
      session.delete("oauth_#{key}")
    end
    cookies.clear_across_domains(:whois, :who, :oauth_social_account_id, :oauth_redirect_to_url)

    return_to = params[:return_to].presence || doc_path(slug: doc_slug)
    session[:doc_auth_pending] = {
      "doc_slug" => doc_slug,
      "return_to" => return_to,
      "landing_referrer" => session[doc_referrer_session_key_for(doc_slug)]
    }

    encrypted_who = MessageEncryptor.encrypt(CallbacksController::DOC_LINE_USER)
    encrypted_whois = MessageEncryptor.encrypt(CallbacksController::TORUYA_USER)

    session[:line_oauth_credentials] = {
      client_id: Rails.application.secrets[:ja][:toruya_line_login_id],
      client_secret: Rails.application.secrets[:ja][:toruya_line_login_secret]
    }
    session[:line_oauth_who_routing] = encrypted_who
    session[:oauth_redirect_to_url] = return_to

    @form_action = user_line_omniauth_authorize_path
    @csrf_token = form_authenticity_token
    @hidden_fields = {
      whois: encrypted_whois,
      who: encrypted_who,
      oauth_redirect_to_url: return_to,
      prompt: "consent",
      bot_prompt: "aggressive"
    }

    render inline: <<~HTML, layout: false
      <!DOCTYPE html>
      <html>
      <head><meta charset="utf-8"><title>LINE ログイン</title></head>
      <body>
        <form id="doc_auth_form" method="post" action="<%= @form_action %>">
          <input type="hidden" name="authenticity_token" value="<%= @csrf_token %>" />
          <% @hidden_fields.each do |name, value| %>
            <input type="hidden" name="<%= name %>" value="<%= value %>" />
          <% end %>
        </form>
        <script>document.getElementById("doc_auth_form").submit();</script>
      </body>
      </html>
    HTML
  end

  private

  def user_line_omniauth_authorize_path
    Rails.application.routes.url_helpers.user_line_omniauth_authorize_path
  end

  def doc_path(slug:)
    Rails.application.routes.url_helpers.doc_path(slug: slug)
  end
end

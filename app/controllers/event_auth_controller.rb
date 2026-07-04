# frozen_string_literal: true

class EventAuthController < ActionController::Base
  include ControllerHelpers
  include LineAuthGateway

  def authorize
    merged = merge_intent_params!({
      "event_slug" => params[:event_slug],
      "return_to" => params[:return_to]
    })
    return if merged.nil?

    event_slug = merged["event_slug"]
    return redirect_to root_path, alert: "イベントが指定されていません" if event_slug.blank?

    event = Event.published.undeleted.find_by(slug: event_slug)
    return redirect_to root_path, alert: "イベントが見つかりません" unless event

    clear_line_oauth_state!

    encrypted_who = MessageEncryptor.encrypt(CallbacksController::EVENT_LINE_USER)
    encrypted_whois = MessageEncryptor.encrypt(CallbacksController::TORUYA_USER)
    oauth_redirect_to_url = merged["return_to"].presence || new_event_participation_path(event_slug: event_slug)

    session[:line_oauth_credentials] = toruya_line_credentials("ja")
    session[:line_oauth_who_routing] = encrypted_who
    session[:oauth_redirect_to_url] = oauth_redirect_to_url

    store_line_auth_pending!(
      purpose: "event",
      event_slug: event_slug,
      return_to: merged["return_to"]
    )

    render_line_oauth_post_form(
      form_id: "event_auth_form",
      hidden_fields: {
        whois: encrypted_whois,
        who: encrypted_who,
        oauth_redirect_to_url: oauth_redirect_to_url,
        prompt: "consent",
        bot_prompt: "aggressive"
      }
    )
  end

  private

  def new_event_participation_path(event_slug:)
    Rails.application.routes.url_helpers.new_event_participation_path(event_slug: event_slug)
  end
end

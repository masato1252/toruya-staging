# frozen_string_literal: true

class EventAuthController < ActionController::Base
  include ControllerHelpers
  include LineAuthGateway

  def authorize
    apply_intent_params!(default_purpose: "event")
    event_slug = params[:event_slug]
    return redirect_to root_path, alert: "イベントが指定されていません" if event_slug.blank?

    event = Event.published.undeleted.find_by(slug: event_slug)
    return redirect_to root_path, alert: "イベントが見つかりません" unless event

    clear_line_oauth_state!

    oauth_redirect_to_url = params[:return_to].presence || new_event_participation_path(event_slug: event_slug)

    session[:line_auth_pending] = {
      "purpose" => "event",
      "event_slug" => event_slug,
      "return_to" => oauth_redirect_to_url
    }

    toruya_user = CallbacksController::TORUYA_USER
    encrypted_who = MessageEncryptor.encrypt(CallbacksController::EVENT_LINE_USER)
    encrypted_whois = MessageEncryptor.encrypt(toruya_user)

    set_toruya_line_oauth_credentials!
    session[:line_oauth_who_routing] = encrypted_who
    session[:oauth_redirect_to_url] = oauth_redirect_to_url

    render_line_omniauth_auto_post(
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

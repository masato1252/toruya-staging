# frozen_string_literal: true

class DocAuthController < ActionController::Base
  include ControllerHelpers
  include LineAuthGateway

  def authorize
    merged = merge_intent_params!({
      "doc_slug" => params[:doc_slug],
      "return_to" => params[:return_to]
    })
    return if merged.nil?

    doc_slug = merged["doc_slug"]
    return redirect_to root_path, alert: "資料が指定されていません" if doc_slug.blank?

    doc = Doc.status_published.active.find_by(slug: doc_slug)
    return redirect_to root_path, alert: "資料が見つかりません" unless doc

    clear_line_oauth_state!

    return_to = merged["return_to"].presence || doc_path(slug: doc_slug)
    landing_referrer = session[doc_referrer_session_key_for(doc_slug)]

    encrypted_who = MessageEncryptor.encrypt(CallbacksController::DOC_LINE_USER)
    encrypted_whois = MessageEncryptor.encrypt(CallbacksController::TORUYA_USER)

    session[:line_oauth_credentials] = toruya_line_credentials("ja")
    session[:line_oauth_who_routing] = encrypted_who
    session[:oauth_redirect_to_url] = return_to

    store_line_auth_pending!(
      purpose: "doc",
      doc_slug: doc_slug,
      return_to: return_to,
      landing_referrer: landing_referrer
    )

    render_line_oauth_post_form(
      form_id: "doc_auth_form",
      hidden_fields: {
        whois: encrypted_whois,
        who: encrypted_who,
        oauth_redirect_to_url: return_to,
        prompt: "consent",
        bot_prompt: "aggressive"
      }
    )
  end

  private

  def doc_path(slug:)
    Rails.application.routes.url_helpers.doc_path(slug: slug)
  end
end

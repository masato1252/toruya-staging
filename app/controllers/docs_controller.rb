# frozen_string_literal: true

class DocsController < ActionController::Base
  layout "booking"

  include ControllerHelpers
  include CompatSession

  protect_from_forgery with: :exception, prepend: true

  before_action :set_doc
  before_action :capture_doc_referrer, only: [:show]

  def show
    if @compat_doc
      if session[:doc_line_user_id].present?
        compat_v1_post(
          "/docs/#{@compat_doc["slug"]}/visit",
          doc_line_user_id: session[:doc_line_user_id],
          referrer: session_doc_referrer
        )
      end
      return
    end

    record_visit_if_logged_in
  end

  def download
    if @compat_doc
      unless session[:doc_line_user_id].present?
        redirect_to doc_path(slug: @compat_doc["slug"]), alert: "LINEログインが必要です"
        return
      end
      result = compat_v1_post(
        "/docs/#{@compat_doc["slug"]}/download",
        doc_line_user_id: session[:doc_line_user_id],
        referrer: session_doc_referrer
      )
      document_url = result&.dig("data", "document_url")
      return redirect_to(document_url, allow_other_host: true) if document_url.present?

      redirect_to doc_path(slug: @compat_doc["slug"]), alert: "資料をダウンロードできませんでした"
      return
    end

    doc_line_user = current_doc_line_user
    unless doc_line_user
      redirect_to doc_path(slug: @doc.slug), alert: "LINEログインが必要です"
      return
    end

    doc_download = @doc.doc_downloads.find_or_initialize_by(doc_line_user: doc_line_user)
    doc_download.record_download!(referrer: session_doc_referrer)

    redirect_to @doc.document_url, allow_other_host: true
  end

  private

  def set_doc
    if compat_admin_enabled?
      @compat_doc = compat_fetch_v1_json(
        "/docs/#{params[:slug]}/page_context",
        doc_line_user_id: session[:doc_line_user_id]
      )&.dig("data")
      return if @compat_doc

      render plain: "資料が見つかりません", status: :not_found
      return
    end

    @doc = Doc.status_published.active.find_by!(slug: params[:slug])
  rescue ActiveRecord::RecordNotFound
    render plain: "資料が見つかりません", status: :not_found
  end

  def current_doc_line_user
    return @_current_doc_line_user if defined?(@_current_doc_line_user)

    @_current_doc_line_user = session[:doc_line_user_id] ? DocLineUser.find_by(id: session[:doc_line_user_id]) : nil
  end
  helper_method :current_doc_line_user

  def capture_doc_referrer
    capture_doc_landing_referrer(@compat_doc&.dig("slug") || @doc.slug)
  end

  def session_doc_referrer
    session[doc_referrer_session_key]
  end

  def doc_referrer_session_key
    doc_referrer_session_key_for(@compat_doc&.dig("slug") || @doc.slug)
  end

  def record_visit_if_logged_in
    doc_line_user = current_doc_line_user
    return unless doc_line_user

    doc_download = @doc.doc_downloads.find_or_initialize_by(doc_line_user: doc_line_user)
    doc_download.record_visit!(referrer: session_doc_referrer)
  end
end

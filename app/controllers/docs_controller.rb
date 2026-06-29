# frozen_string_literal: true

class DocsController < ActionController::Base
  layout "booking"

  include ControllerHelpers

  protect_from_forgery with: :exception, prepend: true

  before_action :set_doc
  before_action :capture_doc_referrer, only: [:show]

  def show
    record_visit_if_logged_in
  end

  def download
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
    capture_doc_landing_referrer(@doc.slug)
  end

  def session_doc_referrer
    session[doc_referrer_session_key]
  end

  def doc_referrer_session_key
    doc_referrer_session_key_for(@doc.slug)
  end

  def record_visit_if_logged_in
    doc_line_user = current_doc_line_user
    return unless doc_line_user

    doc_download = @doc.doc_downloads.find_or_initialize_by(doc_line_user: doc_line_user)
    doc_download.record_visit!(referrer: session_doc_referrer)
  end
end

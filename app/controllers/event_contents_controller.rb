# frozen_string_literal: true

class EventContentsController < ActionController::Base
  layout "booking"
  include ControllerHelpers

  protect_from_forgery with: :exception, prepend: true

  prepend_before_action :set_event
  before_action :set_event_content
  before_action :capture_event_referrers, only: [:show]

  helper ApplicationHelper

  def show
    @current_event_line_user = current_event_line_user
    @participant = @current_event_line_user ? @event.event_participants.find_by(event_line_user_id: @current_event_line_user.id) : nil
    @usage = @current_event_line_user ? @event_content.event_content_usages.find_by(event_line_user_id: @current_event_line_user.id) : nil
    @consultation = @current_event_line_user ? @event_content.event_upsell_consultations.find_by(event_line_user_id: @current_event_line_user.id) : nil
    @monitor_application = @current_event_line_user ? @event_content.event_monitor_applications.find_by(event_line_user_id: @current_event_line_user.id) : nil

    if @current_event_line_user
      ahoy.track("event_content_view", {
        event_content_id: @event_content.id.to_s,
        event_line_user_id: @current_event_line_user.id.to_s
      })
    end

    @event_content_hash = EventContentSerializer.new(@event_content, {
      params: {
        event_line_user: @current_event_line_user,
        participant: @participant,
        usage: @usage,
        consultation: @consultation,
        monitor_application: @monitor_application,
        recommended_seminar_contents: compute_recommended_seminar_contents
      }
    }).attributes_hash
  end

  def start_usage
    @current_event_line_user = current_event_line_user
    return render json: { error: "参加登録が必要です" }, status: :unauthorized unless @current_event_line_user
    return render json: { error: "参加登録が必要です" }, status: :unauthorized unless @event.event_participants.exists?(event_line_user_id: @current_event_line_user.id)

    if @event_content.capacity_full?
      render json: { error: "利用開始の上限に達しました" }, status: :unprocessable_entity
      return
    end

    usage = @event_content.event_content_usages.find_or_initialize_by(event_line_user_id: @current_event_line_user.id)
    if usage.new_record?
      usage.started_at = Time.current
      usage.save!
    end

    if @event_content.seminar_content_type?
      record_stamp(:seminar_view)
    end

    render json: { success: true }
  end

  def upsell_consultation
    @current_event_line_user = current_event_line_user
    return render json: { error: "参加登録が必要です" }, status: :unauthorized unless @current_event_line_user

    consultation = @event_content.event_upsell_consultations.find_or_initialize_by(event_line_user_id: @current_event_line_user.id)
    if consultation.new_record?
      consultation.status = :waitlist
      consultation.save!
      record_stamp(:upsell_consultation)
      Events::NotifyWaitlist.run(consultation: consultation)
    end

    render json: { success: true, status: consultation.status }
  end

  def monitor_apply
    @current_event_line_user = current_event_line_user
    return render json: { error: "参加登録が必要です" }, status: :unauthorized unless @current_event_line_user

    application = @event_content.event_monitor_applications.find_or_initialize_by(event_line_user_id: @current_event_line_user.id)
    if application.new_record?
      application.save!
      record_stamp(:monitor_apply)
      Events::NotifyMonitorApplication.run(application: application)
    end

    form_url = build_monitor_form_url(@event_content, @current_event_line_user)
    render json: { success: true, form_url: form_url }
  end

  def track_activity
    @current_event_line_user = current_event_line_user
    return render json: { error: "ログインが必要です" }, status: :unauthorized unless @current_event_line_user

    activity_type = params[:activity_type]
    unless EventActivityLog.activity_types.key?(activity_type)
      return render json: { error: "不正なアクティビティタイプです" }, status: :unprocessable_entity
    end

    log = EventActivityLog.create!(
      event: @event,
      event_content: @event_content,
      event_line_user: @current_event_line_user,
      activity_type: activity_type,
      metadata: params[:metadata]&.to_unsafe_h || {}
    )

    if activity_type == "material_download"
      record_stamp(:material_download)
    end

    render json: { success: true, id: log.id }
  end

  private

  # コンテンツ詳細(セミナー講演)ページ最下部の「おすすめのセミナー講演」スライダー用に
  # 同じイベント内の他のセミナー講演コンテンツを最大 8 件、参加者の関心ロールを優先して返す。
  # ・現在表示中のコンテンツ自身は除外
  # ・visible_event_contents_for で下書き/プレビュー権限を制御済みの集合のみが対象
  # ・セミナー以外（展示ブース）は対象外
  # ・参加プロフィールがあれば recommended_roles に一致するものを優先
  # ・残り枠はそれ以外のセミナーをシャッフルして埋める
  def compute_recommended_seminar_contents
    return [] unless @event_content.seminar_content_type?

    contents = @event.visible_event_contents_for(@current_event_line_user)
                     .seminar_content_type
                     .where.not(id: @event_content.id)
                     .order(:position)
    has_profile = @participant &&
                  ((@participant.concern_categories || []) - ["other"]).any?

    picked = []
    if has_profile
      roles = @participant.recommended_roles
      matched = contents.to_a.select { |c| ((c.exhibitor_roles || []) & roles).any? }
      picked = matched.first(8)
    end

    if picked.size < 8
      remaining = contents.to_a - picked
      picked += remaining.shuffle.first(8 - picked.size)
    end

    picked
  end

  def set_event
    @event = Event.published.undeleted.find_by!(slug: params[:event_slug])
  rescue ActiveRecord::RecordNotFound
    render plain: "イベントが見つかりません", status: :not_found
  end

  def set_event_content
    # 公開コンテンツ(status=1)は誰でも閲覧可能。
    # 下書き(status=0)はプレビュー権限を持つ viewer のみ閲覧可能(下記 visible_event_contents_for 内で制御)。
    # 権限のない viewer が下書きの URL を直叩きした場合は 404 を返す。
    @event_content = @event.visible_event_contents_for(current_event_line_user).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render plain: "コンテンツが見つかりません", status: :not_found
  end

  def current_event_line_user
    return @_current_event_line_user if defined?(@_current_event_line_user)

    @_current_event_line_user = session[:event_line_user_id] ? EventLineUser.find_by(id: session[:event_line_user_id]) : nil
  end
  helper_method :current_event_line_user

  def record_stamp(action_type)
    return unless @current_event_line_user

    EventStampEntry.find_or_create_by!(
      event: @event,
      event_content: @event_content,
      event_line_user: @current_event_line_user,
      action_type: action_type
    )
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
    # Already recorded — ignore
  end

  def build_monitor_form_url(event_content, event_line_user)
    return nil unless event_content.monitor_form_url.present?

    uri = URI.parse(event_content.monitor_form_url)
    query_params = URI.decode_www_form(uri.query || "")
    query_params << ["entry.line_user_id", event_line_user.line_user_id]
    query_params << ["entry.name", event_line_user.name]
    uri.query = URI.encode_www_form(query_params)
    uri.to_s
  rescue URI::InvalidURIError
    event_content.monitor_form_url
  end
end

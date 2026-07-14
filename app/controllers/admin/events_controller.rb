# frozen_string_literal: true

class Admin::EventsController < AdminController
  before_action :set_event, only: [
    :show, :edit, :update, :destroy, :analytics, :line_messages, :update_line_messages,
    :create_line_message_broadcast, :edit_line_message_broadcast,
    :update_line_message_broadcast, :destroy_line_message_broadcast
  ]
  before_action :set_line_message_broadcast, only: [
    :edit_line_message_broadcast, :update_line_message_broadcast, :destroy_line_message_broadcast
  ]

  def index
    if compat_read_enabled?
      @events = []
      return
    end

    @events = Event.undeleted.order(created_at: :desc)
  end

  def new
    @event = Event.new
  end

  def create
    return render_compat_event_response(compat_event_request(Net::HTTP::Post, "/admin/events")) if compat_read_data_plane?

    @event = Event.new(event_params)

    if @event.save
      redirect_to admin_event_path(@event), notice: "イベントを作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    if compat_read_data_plane?
      @compat_event = compat_fetch_v1_json(
        "/admin/events/#{params[:id]}/page_context"
      )&.dig("data")
      unless @compat_event
        redirect_to admin_events_path, alert: "イベントが見つかりません"
        return
      end
      render :show_compat
      return
    end

    @event_contents = @event.event_contents.undeleted.order(:position)
    @shop_acquisition_rows = @event.admin_shop_acquisition_rows
    @participant_rows = @event.admin_participant_rows
    @participant_counts = @event.admin_participant_count_breakdown
  end

  def edit
    if compat_read_data_plane?
      @compat_event = compat_fetch_v1_json(
        "/admin/events/#{params[:id]}/page_context"
      )&.dig("data")
      unless @compat_event
        redirect_to admin_events_path, alert: "イベントが見つかりません"
        return
      end
      render :edit_compat
    end
  end

  def update
    return render_compat_event_response(
      compat_event_request(Net::HTTP::Put, "/admin/events/#{params[:id]}")
    ) if compat_read_data_plane?

    if @event.update(event_params)
      redirect_to admin_event_path(@event), notice: "イベントを更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if compat_read_data_plane?
      response = compat_v1_json_response(Net::HTTP::Delete, "/admin/events/#{params[:id]}")
      if response&.dig(:success)
        redirect_to admin_events_path, notice: "イベントを削除しました"
      else
        redirect_to admin_events_path, alert: "イベントを削除できませんでした"
      end
      return
    end

    @event.soft_delete!
    redirect_to admin_events_path, notice: "イベントを削除しました"
  end

  def analytics
    if compat_read_data_plane?
      @compat_analytics = compat_fetch_v1_json(
        "/admin/events/#{params[:id]}/analytics/page_context"
      )&.dig("data")
      unless @compat_analytics
        redirect_to admin_event_path(params[:id]), alert: "アクセス解析を取得できませんでした"
        return
      end
      render :analytics_compat
      return
    end

    @event_contents = @event.event_contents.undeleted.order(:position)
    logs_scope = @event.analytics_activity_logs
    @activity_logs = logs_scope.includes(:event_content, :event_line_user).order(created_at: :desc)
    @activity_counts = logs_scope.group(:activity_type).count
    @seminar_activity_counts = logs_scope.joins(:event_content)
                                         .where(event_contents: { content_type: EventContent.content_types[:seminar] })
                                         .group(:activity_type)
                                         .count
    @booth_activity_counts = logs_scope.joins(:event_content)
                                       .where(event_contents: { content_type: EventContent.content_types[:booth] })
                                       .group(:activity_type)
                                       .count
    @content_activity_counts = logs_scope.group(:event_content_id, :activity_type).count
    @overall_access_counts = @event.analytics_access_counts
    @content_access_counts = @event_contents.each_with_object({}) do |content, counts|
      counts[content.id] = @event.analytics_access_counts(content_id: content.id)
    end
  end

  def line_messages
    if compat_read_data_plane?
      return render_compat_line_messages
    end

    build_default_line_message_setting
    build_line_message_broadcasts
  end

  def update_line_messages
    if compat_read_data_plane?
      attributes = line_message_params[:event_line_message_settings_attributes]
      settings =
        if attributes.respond_to?(:to_h)
          attributes.to_h.values
        else
          Array(attributes)
        end
      response = compat_v1_patch(
        "/admin/events/#{params[:id]}/line_messages",
        settings: settings
      )
      if response&.dig("status") == "successful"
        redirect_to line_messages_admin_event_path(params[:id]), notice: "LINEメッセージ設定を保存しました"
      else
        redirect_to line_messages_admin_event_path(params[:id]),
                    alert: response&.dig("error_message") || "LINEメッセージ設定を保存できませんでした"
      end
      return
    end

    if @event.update(line_message_params)
      redirect_to line_messages_admin_event_path(@event), notice: "LINEメッセージ設定を保存しました"
    else
      build_default_line_message_setting
      build_line_message_broadcasts
      render :line_messages, status: :unprocessable_entity
    end
  end

  def create_line_message_broadcast
    if compat_read_data_plane?
      response = compat_v1_post(
        "/admin/events/#{params[:id]}/line_message_broadcasts",
        compat_line_message_broadcast_payload
      )
      return render_compat_broadcast_response(response)
    end

    @event_line_message_broadcast = @event.event_line_message_broadcasts.build(line_message_broadcast_params)
    normalize_broadcast_schedule(@event_line_message_broadcast)

    if @event_line_message_broadcast.save
      enqueue_line_message_broadcast(@event_line_message_broadcast)
      redirect_to line_messages_admin_event_path(@event), notice: "一括配信を作成しました"
    else
      build_default_line_message_setting
      build_line_message_broadcasts
      render :line_messages, status: :unprocessable_entity
    end
  end

  def edit_line_message_broadcast
    if compat_read_data_plane?
      return render_compat_line_messages(params[:broadcast_id])
    end

    unless @event_line_message_broadcast.editable?
      redirect_to line_messages_admin_event_path(@event), alert: "配信開始後の一括配信は編集できません"
      return
    end

    build_default_line_message_setting
    build_line_message_broadcasts(editing_broadcast: @event_line_message_broadcast)
    render :line_messages
  end

  def update_line_message_broadcast
    if compat_read_data_plane?
      response = compat_v1_put(
        "/admin/events/#{params[:id]}/line_message_broadcasts/#{params[:broadcast_id]}",
        compat_line_message_broadcast_payload
      )
      return render_compat_broadcast_response(response)
    end

    unless @event_line_message_broadcast.editable?
      redirect_to line_messages_admin_event_path(@event), alert: "配信開始後の一括配信は編集できません"
      return
    end

    @event_line_message_broadcast.assign_attributes(line_message_broadcast_params)
    normalize_broadcast_schedule(@event_line_message_broadcast)

    if @event_line_message_broadcast.save
      enqueue_line_message_broadcast(@event_line_message_broadcast)
      redirect_to line_messages_admin_event_path(@event), notice: "一括配信を更新しました"
    else
      build_default_line_message_setting
      build_line_message_broadcasts(editing_broadcast: @event_line_message_broadcast)
      render :line_messages, status: :unprocessable_entity
    end
  end

  def destroy_line_message_broadcast
    if compat_read_data_plane?
      response = compat_v1_delete(
        "/admin/events/#{params[:id]}/line_message_broadcasts/#{params[:broadcast_id]}"
      )
      if response&.dig("status") == "successful"
        redirect_to line_messages_admin_event_path(params[:id]), notice: "一括配信を取り消しました"
      else
        redirect_to line_messages_admin_event_path(params[:id]),
                    alert: response&.dig("error_message") || "一括配信を取り消せませんでした"
      end
      return
    end

    unless @event_line_message_broadcast.cancellable?
      redirect_to line_messages_admin_event_path(@event), alert: "配信開始後の一括配信は取り消しできません"
      return
    end

    @event_line_message_broadcast.update!(status: :cancelled)
    redirect_to line_messages_admin_event_path(@event), notice: "一括配信を取り消しました"
  end

  # イベント新規作成時にも使えるよう、event_contents の同名アクションを events 側にも用意。
  # マスタプレビュー権限店舗の選択用 user_id 検索。
  def shops_by_user
    if compat_read_data_plane?
      rows = compat_fetch_v1_json(
        "/admin/events/shops_by_user",
        user_id: params[:user_id]
      )
      render json: rows || []
      return
    end

    user = User.find_by(id: params[:user_id])
    return render json: [] unless user

    shops = user.shops.map { |s| { id: s.id, name: s.name } }
    render json: shops
  end

  private

  def set_event
    return if compat_read_data_plane? && %w[
      show edit update destroy update_line_messages
      create_line_message_broadcast update_line_message_broadcast destroy_line_message_broadcast
      line_messages edit_line_message_broadcast
      analytics
    ].include?(action_name)

    @event = Event.undeleted.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_events_path, alert: "イベントが見つかりません"
  end

  def set_line_message_broadcast
    return if compat_read_data_plane? && %w[
      update_line_message_broadcast destroy_line_message_broadcast
      edit_line_message_broadcast
    ].include?(action_name)

    @event_line_message_broadcast = @event.event_line_message_broadcasts.find(params[:broadcast_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to line_messages_admin_event_path(@event), alert: "一括配信が見つかりません"
  end

  def event_params
    permitted = params.require(:event).permit(
      :title, :slug, :description, :start_at, :end_at, :published,
      :hero_image, :logo_image, :stamp_rally_description,
      :master_preview_shop_id,
      stamp_rally_phases: [:title, :start_on, :end_on]
    )
    # 期間設定はチェックボックス的な送信がないフォーム上「何も行を残さない状態」では
    # パラメータキー自体が消える。その場合は空配列扱いで上書きする(= 全削除)。
    permitted[:stamp_rally_phases] ||= [] if params[:event].key?(:stamp_rally_phases_present)
    permitted
  end

  def compat_event_request(request_class, path)
    permitted = event_params
    logo_image = permitted.delete(:logo_image)
    permitted.delete(:hero_image)
    payload = permitted.to_h
    payload[:stamp_rally_phases] = payload[:stamp_rally_phases].to_json if payload[:stamp_rally_phases]
    if logo_image.present?
      compat_v1_multipart_response(request_class, path, payload, logo_image: logo_image)
    else
      compat_v1_json_response(request_class, path, payload)
    end
  end

  def render_compat_event_response(response)
    if response&.dig(:success) && response.dig(:body, "status") == "successful"
      redirect_to response.dig(:body, "redirect_to") || admin_events_path,
                  notice: "イベントを保存しました"
    else
      redirect_back fallback_location: admin_events_path,
                    alert: response&.dig(:body, "error_message") || "イベントを保存できませんでした"
    end
  end

  def line_message_params
    params.require(:event).permit(
      event_line_message_settings_attributes: [
        :id,
        :enabled,
        :starts_at,
        :ends_at,
        :message,
        :position,
        :_destroy
      ]
    )
  end

  def line_message_broadcast_params
    params.require(:event_line_message_broadcast).permit(:scheduled_at, :message)
  end

  def compat_line_message_broadcast_payload
    line_message_broadcast_params.to_h.merge(delivery_type: params[:delivery_type])
  end

  def render_compat_broadcast_response(response)
    if response&.dig("status") == "successful"
      broadcast = EventLineMessageBroadcast.find_by(id: response["id"])
      enqueue_line_message_broadcast(broadcast) if broadcast && !response["job_enqueued"]
      redirect_to response["redirect_to"] || line_messages_admin_event_path(params[:id]),
                  notice: "一括配信を保存しました"
    else
      redirect_to line_messages_admin_event_path(params[:id]),
                  alert: response&.dig("error_message") || "一括配信を保存できませんでした"
    end
  end

  def render_compat_line_messages(editing_broadcast_id = nil)
    @compat_line_messages = compat_fetch_v1_json(
      "/admin/events/#{params[:id]}/line_messages/page_context",
      editing_broadcast_id: editing_broadcast_id
    )&.dig("data")
    unless @compat_line_messages
      redirect_to admin_events_path, alert: "LINEメッセージ設定を取得できませんでした"
      return
    end
    render :line_messages_compat
  end

  def build_default_line_message_setting
    return if @event.event_line_message_settings.any?

    @event.event_line_message_settings.build(
      enabled: true,
      starts_at: Time.current.change(sec: 0),
      position: 0
    )
  end

  def build_line_message_broadcasts(editing_broadcast: nil)
    @event_line_message_broadcast ||= @event.event_line_message_broadcasts.build(
      scheduled_at: Time.current.change(sec: 0)
    )
    @editing_event_line_message_broadcast = editing_broadcast
    @event_line_message_broadcasts = EventLineMessageBroadcast.where(event: @event).recent.includes(:event_line_message_broadcast_deliveries)
    @registered_event_line_users_count = @event.event_participants.where.not(event_line_user_id: nil).select(:event_line_user_id).distinct.count
  end

  def normalize_broadcast_schedule(broadcast)
    if params[:delivery_type] == "immediate" || broadcast.scheduled_at.blank?
      broadcast.scheduled_at = Time.current
    else
      broadcast.scheduled_at = broadcast.scheduled_at.change(sec: 0)
    end
  end

  def enqueue_line_message_broadcast(broadcast)
    if broadcast.scheduled_at.future?
      EventLineMessageBroadcastJob.set(wait_until: broadcast.scheduled_at).perform_later(broadcast)
    else
      EventLineMessageBroadcastJob.perform_later(broadcast)
    end
  end
end

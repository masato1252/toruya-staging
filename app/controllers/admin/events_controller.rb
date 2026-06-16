# frozen_string_literal: true

class Admin::EventsController < AdminController
  before_action :set_event, only: [:show, :edit, :update, :destroy, :analytics, :line_messages, :update_line_messages]

  def index
    @events = Event.undeleted.order(created_at: :desc)
  end

  def new
    @event = Event.new
  end

  def create
    @event = Event.new(event_params)

    if @event.save
      redirect_to admin_event_path(@event), notice: "イベントを作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @event_contents = @event.event_contents.undeleted.order(:position)
    @shop_acquisition_rows = @event.admin_shop_acquisition_rows
    @participant_rows = @event.admin_participant_rows
    @participant_counts = @event.admin_participant_count_breakdown
  end

  def edit
  end

  def update
    if @event.update(event_params)
      redirect_to admin_event_path(@event), notice: "イベントを更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @event.soft_delete!
    redirect_to admin_events_path, notice: "イベントを削除しました"
  end

  def analytics
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
    build_default_line_message_setting
  end

  def update_line_messages
    if @event.update(line_message_params)
      redirect_to line_messages_admin_event_path(@event), notice: "LINEメッセージ設定を保存しました"
    else
      build_default_line_message_setting
      render :line_messages, status: :unprocessable_entity
    end
  end

  # イベント新規作成時にも使えるよう、event_contents の同名アクションを events 側にも用意。
  # マスタプレビュー権限店舗の選択用 user_id 検索。
  def shops_by_user
    user = User.find_by(id: params[:user_id])
    return render json: [] unless user

    shops = user.shops.map { |s| { id: s.id, name: s.name } }
    render json: shops
  end

  private

  def set_event
    @event = Event.undeleted.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_events_path, alert: "イベントが見つかりません"
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

  def build_default_line_message_setting
    return if @event.event_line_message_settings.any?

    @event.event_line_message_settings.build(
      enabled: true,
      starts_at: Time.current.change(sec: 0),
      position: 0
    )
  end
end

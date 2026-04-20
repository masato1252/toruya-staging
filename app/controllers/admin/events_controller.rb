# frozen_string_literal: true

class Admin::EventsController < AdminController
  before_action :set_event, only: [:show, :edit, :update, :destroy, :analytics]

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
    @participants = @event.event_participants.includes(:event_line_user).order(registered_at: :desc)
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
    @activity_logs = @event.event_activity_logs
                          .includes(:event_content, :event_line_user)
                          .order(created_at: :desc)
    @activity_counts = @event.event_activity_logs.group(:activity_type).count
    @content_activity_counts = @event.event_activity_logs.group(:event_content_id, :activity_type).count
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
end

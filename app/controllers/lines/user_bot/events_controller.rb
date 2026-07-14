# frozen_string_literal: true

class Lines::UserBot::EventsController < Lines::UserBotDashboardController
  before_action :redirect_to_admin, unless: :compat_read_enabled?

  def index
    render :index_compat if compat_read_enabled?
  end

  def new
    if compat_read_data_plane?
      render :new_compat
      return
    end
  end

  def create
    return redirect_to_admin unless compat_read_data_plane?

    owner_id = resolve_compat_owner_id(nil) || resolve_compat_current_user_id(nil)
    result = compat_v1_post("/lines/user_bot/owner/#{owner_id}/events", event_params)
    render json: result || { status: "failed", error_message: "イベントを作成できませんでした" },
           status: (result&.dig("status") == "successful" ? :ok : :unprocessable_entity)
  end

  def show
    if compat_read_data_plane?
      render :show_compat
      return
    end
  end

  def edit
    if compat_read_data_plane?
      render :edit_compat
      return
    end
  end

  def update
    return redirect_to_admin unless compat_read_data_plane?

    owner_id = resolve_compat_owner_id(nil) || resolve_compat_current_user_id(nil)
    result = compat_v1_put("/lines/user_bot/owner/#{owner_id}/events/#{params[:id]}", event_params)
    render json: result || { status: "failed", error_message: "イベントを更新できませんでした" },
           status: (result&.dig("status") == "successful" ? :ok : :unprocessable_entity)
  end

  def destroy
    return redirect_to_admin unless compat_read_data_plane?

    owner_id = resolve_compat_owner_id(nil) || resolve_compat_current_user_id(nil)
    result = compat_v1_delete("/lines/user_bot/owner/#{owner_id}/events/#{params[:id]}")

    redirect_to lines_user_bot_events_path(business_owner_id: owner_id),
                notice: (I18n.t("common.delete_successfully_message") if result&.dig("status") == "successful"),
                alert: (result&.dig("error_message") unless result&.dig("status") == "successful")
  end
  def analytics; end

  private

  def event_params
    params.permit(:title, :slug, :description, :start_at, :end_at, :published).to_h
  end

  def redirect_to_admin
    redirect_to admin_events_path, notice: "イベント管理はAdmin画面に移動しました"
  end
end

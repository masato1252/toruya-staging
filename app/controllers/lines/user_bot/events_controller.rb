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

  def create; end

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

  def update; end

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

  def redirect_to_admin
    redirect_to admin_events_path, notice: "イベント管理はAdmin画面に移動しました"
  end
end

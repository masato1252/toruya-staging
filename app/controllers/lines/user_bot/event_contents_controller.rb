# frozen_string_literal: true

class Lines::UserBot::EventContentsController < Lines::UserBotDashboardController
  before_action :redirect_to_admin, unless: :compat_read_enabled?

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
  def destroy; end
  def upload_image; end
  def destroy_image; end
  def shops_by_user; end
  def online_services_for_shop; end

  private

  def redirect_to_admin
    redirect_to admin_events_path, notice: "イベント管理はAdmin画面に移動しました"
  end
end

# frozen_string_literal: true

class Lines::UserBot::EventContentsController < Lines::UserBotDashboardController
  before_action :redirect_to_admin

  def new; end
  def create; end
  def show; end
  def edit; end
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

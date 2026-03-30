# frozen_string_literal: true

class Lines::UserBot::EventsController < Lines::UserBotDashboardController
  before_action :redirect_to_admin

  def index; end
  def new; end
  def create; end
  def show; end
  def edit; end
  def update; end
  def destroy; end
  def analytics; end

  private

  def redirect_to_admin
    redirect_to admin_events_path, notice: "イベント管理はAdmin画面に移動しました"
  end
end

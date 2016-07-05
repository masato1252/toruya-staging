class DashboardController < ActionController::Base
  layout "dashboard"
  protect_from_forgery with: :exception, prepend: true

  before_action :authenticate_user!

  def shops
    @shops = current_user.shops
  end
  helper_method :shops
end

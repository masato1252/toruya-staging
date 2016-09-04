class HomeController < DashboardController
  layout "home"

  def index
    @shops = super_user.shops
  end
end

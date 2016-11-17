class HomeController < DashboardController
  layout "home"

  def index
    @shops = super_user.shops.order("id")
  end
end

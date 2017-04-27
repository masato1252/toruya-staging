class HomeController < DashboardController
  layout "home"

  def index
    @shops = super_user.shops.order("id")
    if @shops.count == 1
      redirect_to shop_reservations_path(@shops.first)
    end
  end
end

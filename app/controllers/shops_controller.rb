class ShopsController < ActionController::Base
  layout "booking"

  def show
    @shop = Shop.find(params[:id])
  end
end

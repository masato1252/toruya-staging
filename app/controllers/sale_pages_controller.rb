class SalePagesController < ActionController::Base
  layout "booking"

  def show
    @sale_page ||= SalePage.find(params[:id])
  end
end

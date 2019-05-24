class BookingPagesController < ActionController::Base
  layout "booking"

  def show
    @booking_page = BookingPage.find(params[:id])
  end
end

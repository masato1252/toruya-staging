class BookingPagesController < ActionController::Base
  def show
    @booking_page = BookingPage.find(params[:id])

    render html: "page #{@booking_page.title}"
  end
end

class BookingsController < ActionController::Base
  skip_before_action :verify_authenticity_token

  layout "booking"

  def show
    @reservation_customer = ReservationCustomer.find_by(slug: params[:slug])
    @reservation = @reservation_customer.reservation
    @customer = @reservation_customer.customer
    @shop = @reservation_customer.customer.user.shops.first
  end

  def destroy
    reservation_customer = ReservationCustomer.find_by(slug: params[:slug])
    ReservationCustomers::CustomerCancel.run!(
      reservation_customer: reservation_customer,
      cancel_reason: "#{params[:cancel_reason]&.join(',')},#{params[:other_reason]}"
    )

    redirect_to booking_path(reservation_customer.slug)
  end
end

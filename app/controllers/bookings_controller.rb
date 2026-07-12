class BookingsController < ActionController::Base
  include ProductLocale
  include CompatSession

  skip_before_action :verify_authenticity_token

  layout "booking"

  def show
    @reservation = reservation_customer.reservation
    @customer = reservation_customer.customer
    @shop = reservation_customer.customer.user.shops.first
  end

  def destroy
    if compat_read_data_plane?
      result = compat_v1_delete(
        "/bookings/#{params[:slug]}",
        cancel_reason: params[:cancel_reason],
        other_reason: params[:other_reason]
      )
      unless result&.dig("status") == "successful"
        Rails.logger.warn("[BookingCancel] compat cancellation failed", slug: params[:slug])
      end
      redirect_to booking_path(params[:slug])
      return
    end

    outcome = ReservationCustomers::CustomerCancel.run(
      reservation_customer: reservation_customer,
      cancel_reason: "#{params[:cancel_reason]&.join(',')},#{params[:other_reason]}"
    )

    if outcome.invalid?
      Rollbar.error("ReservationCustomers::CustomerCancel", details: outcome.errors.details, slug: reservation_customer.slug)
    end

    redirect_to booking_path(reservation_customer.slug)
  end

  private

  def reservation_customer
    @reservation_customer ||= ReservationCustomer.find_by(slug: params[:slug])
  end

  def product_social_user
    reservation_customer.customer.user.social_user
  end
end

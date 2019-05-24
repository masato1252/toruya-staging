class BookingPagesController < ActionController::Base
  layout "booking"

  def show
    @booking_page = BookingPage.find(params[:id])
    if cookies[:booking_customer_id]
      @customer = @booking_page.user.customers.find(cookies[:booking_customer_id]).with_google_contact
    end
  end

  def find_customer
    customer = Booking::FindCustomer.run!(
      booking_page: BookingPage.find(params[:id]),
      first_name: params[:customer_first_name],
      last_name: params[:customer_last_name],
      phone_number: params[:customer_phone_number]
    )

    if customer
      render json: {
        found_customer_info: {
          id: customer.id,
          simple_address: customer.address,
          full_address: customer.display_address,
          address_details: customer.primary_address,
          email: customer.primary_email,
          phone: customer.primary_phone,
          first_name: customer.first_name,
          last_name: customer.last_name,
          phonetic_first_name: customer.phonetic_first_name,
          phonetic_last_name: customer.phonetic_last_name
        }
      }
    else
      render json: {}
    end
  end

  private
end

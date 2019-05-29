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
      if ActiveModel::Type::Boolean.new.cast(params[:remember_me])
        cookies[:booking_customer_id] = customer.id
        cookies[:booking_customer_phone_number] = params[:customer_phone_number]
      else
        cookies.delete :booking_customer_id
        cookies.delete :booking_customer_phone_number
      end

      render json: {
        customer_info: {
          id: customer.id,
          first_name: customer.first_name,
          last_name: customer.last_name,
          phonetic_first_name: customer.phonetic_first_name,
          phonetic_last_name: customer.phonetic_last_name,
          phone_number: params[:customer_phone_number],
          phone_numbers: customer.phone_numbers.map { |phone| phone.value.gsub(/[^0-9]/, '') },
          email: customer.primary_email&.value&.address,
          emails: customer.emails.map { |email| email.value.address },
          simple_address: customer.address,
          full_address: customer.display_address,
          address_details: customer.primary_address&.value,
          original_address_details: customer.primary_address&.value
        }
      }
    else
      render json: {
        customer_info: {}
      }
    end
  end

  private
end

module BookingHelper
  def customer_info_as_json(customer_with_google_contact)
    customer_with_google_contact = customer_with_google_contact.with_google_contact

    {
      id: customer_with_google_contact&.id,
      first_name: customer_with_google_contact&.first_name,
      last_name: customer_with_google_contact&.last_name,
      phonetic_first_name: customer_with_google_contact&.phonetic_first_name,
      phonetic_last_name: customer_with_google_contact&.phonetic_last_name,
      phone_number: params[:customer_phone_number] || cookies[:booking_customer_phone_number],
      phone_numbers: customer_with_google_contact&.phone_numbers&.map { |phone| phone.value.gsub(/[^0-9]/, '') },
      email: customer_with_google_contact&.primary_email&.value&.address,
      emails: customer_with_google_contact&.emails&.map { |email| email.value.address },
      simple_address: customer_with_google_contact&.address,
      full_address: customer_with_google_contact&.display_address,
      address_details: customer_with_google_contact&.primary_formatted_address&.value,
      original_address_details: customer_with_google_contact&.primary_address&.value
    }
  end
end


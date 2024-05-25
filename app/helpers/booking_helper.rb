# frozen_string_literal: true

module BookingHelper
  def customer_info_as_json(customer)
    {
      id: customer&.id,
      first_name: customer&.first_name,
      last_name: customer&.last_name,
      phonetic_first_name: customer&.phonetic_first_name,
      phonetic_last_name: customer&.phonetic_last_name,
      phone_number: params[:customer_phone_number]&.presence || customer&.mobile_phone_number,
      phone_numbers: customer&.phone_numbers_details&.map { |phone| phone&.dig("value")&.gsub(/[^0-9]/, '') }&.compact || [],
      email: customer&.email,
      emails: customer&.emails_details&.map { |email| email["value"] }&.compact || [],
      simple_address: customer&.simple_address,
      full_address: customer&.display_address,
      address_details: customer&.address_details,
      original_address_details: customer&.address_details
    }
  end
end


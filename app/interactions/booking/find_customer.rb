# frozen_string_literal: true

module Booking
  class FindCustomer < ActiveInteraction::Base
    object :booking_page, class: "BookingPage"
    string :last_name
    string :first_name
    string :phone_number

    def execute
      customers_hash = compose(
        Customers::Find,
        user: booking_page.user,
        last_name: last_name,
        first_name: first_name,
        phone_number: phone_number
      )

      if customers_hash[:matched_customers].length > 1
        SlackClient.send(channel: 'toruya_users_support', text: "user_id: #{booking_page.user_id}, had duplicate_customers #{customers_hash[:matched_customers].map(&:id)}, had same name #{customers_hash[:found_customer].name} and phone_number #{phone_number}")
      end

      customers_hash[:found_customer]
    end
  end
end

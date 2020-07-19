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
        NotificationMailer.duplicate_customers(
          booking_page,
          customers_hash[:matched_customers],
          customers_hash[:found_customer],
          phone_number
        ).deliver_later
      end

      customers_hash[:found_customer]
    end
  end
end

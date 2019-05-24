module Booking
  class FindCustomer < ActiveInteraction::Base
    object :booking_page, class: "BookingPage"
    string :last_name
    string :first_name
    string :phone_number

    def execute
      user_customers = user.customers
      matched_customers = user_customers.where(last_name: last_name, first_name: first_name).or(user_customers.where(phonetic_last_name: last_name, phonetic_first_name: first_name)).to_a

      if matched_customers.length == 1
        matched_customers.first.with_google_contact
      elsif matched_customers.length > 1
        # [TODO]
        # email owner customer duplication notification

        matched_phone_customer = matched_customers.find do |matched_customer|
          matched_customer.with_google_contact.primary_phone&.value&.gsub(/[^0-9]/, '') == phone_number.gsub(/[^0-9]/, '')
        end

        if matched_phone_customer
          matched_phone_customer.with_google_contact
        else
          sql = matched_customers.map(&:id).map { |customer_id| "customer_id = #{customer_id}" }.join(" OR ")
          last_reservation_customer = ReservationCustomer.where(Arel.sql(sql)).order("id").last
          last_reservation_customer = matched_customers.find { |matched_customer| matched_customer.id == last_reservation_customer&.customer_id }

          if last_reservation_customer
            last_reservation_customer.with_google_contact
          else
            matched_customers.sort_by(&:id).last.with_google_contact
          end
        end
      end
    end

    private

    def user
      @user ||= booking_page.user
    end
  end
end

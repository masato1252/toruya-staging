# frozen_string_literal: true

module Customers
  class Find < ActiveInteraction::Base
    object :user
    string :last_name
    string :first_name
    string :phone_number

    def execute
      user_customers = user.customers.order("id")
      customers = nil

      with_retry(max_reties: 1) do
        customers = user_customers.where(last_name: last_name, first_name: first_name).or(user_customers.where(phonetic_last_name: last_name, phonetic_first_name: first_name)).to_a
        raise "retry on purpose" # somehow, it is race condition, it doesn't find the data when data should be exist
      end

      matched_customers = customers.find_all do |customer|
        customer.phone_numbers_details&.map { |phone| phone["value"].gsub(/[^0-9]/, '') }&.include?(phone_number.gsub(/[^0-9]/, ''))
      end

      booking_customer =
        if matched_customers.length == 1
          matched_customers.first
        elsif matched_customers.length > 1
          sql = matched_customers.map(&:id).map { |customer_id| "customer_id = #{customer_id}" }.join(" OR ")
          last_reservation_customer = ReservationCustomer.where(Arel.sql(sql)).order("id").last
          last_reservation_customer = matched_customers.find { |matched_customer| matched_customer.id == last_reservation_customer&.customer_id }

          last_reservation_customer || matched_customers.sort_by(&:id).last
        end

      {
        found_customer: booking_customer,
        matched_customers: matched_customers
      }
    end
  end
end

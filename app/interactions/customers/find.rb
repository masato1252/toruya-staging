# frozen_string_literal: true

module Customers
  class Find < ActiveInteraction::Base
    object :user
    string :last_name
    string :first_name
    string :phone_number, default: nil
    string :email, default: nil

    def execute
      user_customers = user.customers.order("id")
      customers = user_customers.where(customer_email: email) if email.present?
      if phone_number.present?
        parsed_phone = Phonelib.parse(phone_number)
        parsed_phone = Phonelib.parse(phone_number, "JP") unless parsed_phone.valid?
        customers = customers.presence || user_customers.where(customer_phone_number: parsed_phone.international(false))
      end

      if customers.present?
        return {
          found_customer: customers.first,
          matched_customers: customers
        }
      end

      with_retry(max_reties: 1) do
        customers = user_customers.where(last_name: last_name, first_name: first_name).or(user_customers.where(phonetic_last_name: last_name, phonetic_first_name: first_name)).to_a
        raise "retry on purpose" # somehow, it is race condition, it doesn't find the data when data should be exist
      end

      matched_customers = customers.find_all do |customer|
        customer.customer_email == email ||
        customer.phone_numbers_details&.map { |phone| phone["value"]&.gsub(/[^0-9]/, '') }.compact&.include?(phone_number&.gsub(/[^0-9]/, '')) ||
        customer.emails_details&.map { |email| email["value"] }.compact&.include?(email)
      end

      # any customer got social customer
      matched_customers = matched_customers.presence || customers.find_all do |customer|
        customer.social_customer.present?
      end

      # any customer updated in 180 days ago
      matched_customers = matched_customers.presence || customers.find_all do |customer|
        customer.updated_at >= 180.days.ago
      end

      booking_customer =
        if matched_customers.length == 1
          matched_customers.first
        elsif matched_customers.length > 1
          sql = matched_customers.map(&:id).map { |customer_id| "customer_id = #{customer_id}" }.join(" OR ")
          last_reservation_customer = ReservationCustomer.where(Arel.sql(sql)).order("id").last
          last_reservation_customer = matched_customers.find { |matched_customer| matched_customer.id == last_reservation_customer&.customer_id }

          last_reservation_customer || matched_customers.select { |customer| customer.social_customer.present? }&.sort_by(&:id)&.last || matched_customers.sort_by(&:id).last
        end

      {
        found_customer: booking_customer,
        matched_customers: matched_customers
      }
    end
  end
end

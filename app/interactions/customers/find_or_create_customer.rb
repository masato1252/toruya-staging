# frozen_string_literal: true

module Customers
  class FindOrCreateCustomer < ActiveInteraction::Base
    object :user
    object :social_customer, default: nil
    string :last_name
    string :first_name
    string :phonetic_last_name, default: nil
    string :phonetic_first_name, default: nil
    string :phone_number
    string :email, default: nil

    def execute
      customer_from_social_customer = social_customer&.customer
      customer = find_customer # customer might nil

      if customer_from_social_customer || customer
        if customer_from_social_customer != customer
          if customer.present?
            social_customer.update(customer: customer) if social_customer.present?

            if customer_from_social_customer.present? &&
              !customer_from_social_customer.reservations.exists? &&
               customer_from_social_customer.online_service_customer_relations.exists?
              customer_from_social_customer.update(deleted_at: Time.current)
            end
          elsif customer_from_social_customer.present?
            customer = customer_from_social_customer
          end
        end
      else
        customer = create_customer
      end

      # Update customer with any new information
      update_customer(customer) if customer

      customer
    end

    private

    def find_customer
      customers_hash = compose(
        Customers::Find,
        user: user,
        last_name: last_name,
        first_name: first_name,
        phone_number: phone_number,
        email: email
      )

      customers_hash[:found_customer]
    end

    def create_customer
      Customer.create!(
        last_name: last_name,
        first_name: first_name,
        phonetic_last_name: phonetic_last_name,
        phonetic_first_name: phonetic_first_name,
        phone_numbers_details: format_phone_numbers,
        emails_details: format_emails,
        user_id: user.id
      )
    rescue ActiveRecord::RecordInvalid => e
      errors.add(:base, e.message)
      nil
    end

    def update_customer(customer)
      customer_attrs = {}

      if phone_number.present?
        customer_attrs[:phone_numbers_details] = [{ "type" => "mobile", "value" => phone_number }]
      end

      # Only update these fields if they're provided and different from current values
      if email.present?
        customer_attrs[:emails_details] = [{ "type" => "mobile", "value" => email }]
      end

      if phonetic_last_name.present? && customer.phonetic_last_name != phonetic_last_name
        customer_attrs[:phonetic_last_name] = phonetic_last_name
      end

      if phonetic_first_name.present? && customer.phonetic_first_name != phonetic_first_name
        customer_attrs[:phonetic_first_name] = phonetic_first_name
      end

      # Update the customer if we have any attributes to update
      customer.update(customer_attrs) if customer_attrs.present?

      customer
    end

    def format_phone_numbers
      return [] unless phone_number.present?
      [{ "type" => "mobile", "value" => phone_number }]
    end

    def format_emails
      return [] unless email.present?
      [{ "type" => "mobile", "value" => email }]
    end
  end
end

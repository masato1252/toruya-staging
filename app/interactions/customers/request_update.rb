# frozen_string_literal: true

class Customers::RequestUpdate < ActiveInteraction::Base
  object :reservation_customer

  def execute
    customer.attributes = new_customer_info.name_attributes
    assign_emails
    assign_phone_numbers
    assign_address

    if customer.valid?
      customer.email_types = Array.wrap(customer.emails_details).map{|email| email["type"] }.uniq.sort.join(",")
      customer.save
      customer
    end
  end

  private

  def customer
    @customer ||= reservation_customer.customer
  end

  def new_customer_info
    @new_customer_info ||= reservation_customer.customer_info
  end

  def user
    customer.user
  end

  def assign_emails
    if new_customer_info.email
      if customer.emails_details.blank?
        customer.emails_details = [{ type: "mobile", value: new_customer_info.email }]
      else
        current_emails = customer.emails_details

        primary_email = current_emails[0]
        primary_email["value"]= new_customer_info.email
        current_emails[0] = primary_email

        customer.emails_details = current_emails
      end
    end
  end

  def assign_phone_numbers
    if new_customer_info.phone_number
      if customer.phone_numbers_details.blank?
        customer.phone_numbers_details = [{ type: "mobile", value: new_customer_info.phone_number }]
      else
        current_phones = customer.phone_numbers_details

        primary_phone = current_phones[0]
        primary_phone["value"] = new_customer_info.phone_number
        current_phones[0] = primary_phone

        customer.phone_numbers_details = current_phones
      end
    end
  end

  def assign_address
    if new_customer_info.sorted_address_details.present?
      current_address = customer.address_details

      customer.address_details = {
        zip_code: new_customer_info.address_details.zip_code.presence || current_address&.dig("zip_code"),
        region: new_customer_info.address_details.region.presence || current_address&.dig("region"),
        city: new_customer_info.address_details.city.presence || current_address&.dig("city"),
        street1: new_customer_info.address_details.street1.presence || current_address&.dig("street1"),
        street2: new_customer_info.address_details.street2.presence || current_address&.dig("street2")
      }
    end
  end
end

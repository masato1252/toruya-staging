# frozen_string_literal: true

class Customers::SyncData < ActiveInteraction::Base
  object :customer
  # toruya_base
  # true: sync toruya data to google
  # false: sync google data to toruya
  boolean :toruya_base, default: true

  def execute
    if toruya_base
      # TDDO: Inmplement in the future, we don't have a lot of users would have google account,
      # and we would use our toruya customer data as first priority, so postpone this until we
      # needd to sync data to google at one day.
    else
      # Google to Toruya
      customer_with_google_contact = customer.with_google_contact
      return if customer_with_google_contact.google_contact_id.blank? || customer_with_google_contact.google_down

      customer.emails_details = Array.wrap(customer_with_google_contact.emails).map do |email|
        {
          type: email.type,
          value: email.value.address,
        }
      end
      customer.phone_numbers_details = Array.wrap(customer_with_google_contact.phone_numbers).map do |phone_number|
        {
          type: phone_number.type,
          value: phone_number.value
        }
      end

      address = customer_with_google_contact.primary_address&.value

      if address
        streets = address.street ? address.street.split(",") : []
        street1 = streets.first
        street2 = streets[1..-1].try(:join, ",")

        customer.address_details = {
          zip_code: address.postcode,
          region: address.region,
          city: address.city,
          street1: street1,
          street2: street2
        }
      end

      customer.save
    end
  end

  private

  def user
    @user ||= customer.user
  end
end

# frozen_string_literal: true

class Customers::Create < ActiveInteraction::Base
  object :user
  string :customer_last_name
  string :customer_first_name
  string :customer_phonetic_last_name, default: nil
  string :customer_phonetic_first_name, default: nil
  string :customer_phone_number, default: nil
  string :customer_email, default: nil
  boolean :customer_reminder_permission, default: false

  def execute
    begin
      customer_info_hash = {
        last_name: customer_last_name,
        first_name: customer_first_name,
        phonetic_last_name: customer_phonetic_last_name,
        phonetic_first_name: customer_phonetic_first_name,
        reminder_permission: customer_reminder_permission
      }

      if customer_email
        customer_info_hash.merge!(
          email_types: "mobile",
          emails: [{ type: "mobile", value: { address: customer_email }, primary: true }],
          emails_details: [{ type: "mobile", value: customer_email }],
        )
      end

      if customer_phone_number
        customer_info_hash.merge!(
          phone_numbers: [{ type: "mobile", value: customer_phone_number, primary: true }],
          phone_numbers_details: [{ type: "mobile", value: customer_phone_number }],
        )
      end

      customer = user.customers.new(customer_info_hash)
      # google_user = user.google_user
      #
      # if google_user
      #   result = google_user.create_contact(customer.google_contact_attributes)
      #   customer.google_contact_id = result.id
      #   customer.google_uid = user.uid
      # end

    rescue => e
      # XXX: Even google is down, we still support the customer creation process
      Rollbar.error(e)
      # errors.add(:base, :google_down)
    end

    if user.contact_groups.count == 1
      customer.contact_group_id = user.contact_groups.first.id
    end

    customer.save

    if customer.new_record?
      errors.merge!(customer.errors)
    else
      CustomersLimitReminderJob.perform_later(user)
    end

    customer
  end
end

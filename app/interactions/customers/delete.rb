# frozen_string_literal: true

class Customers::Delete < ActiveInteraction::Base
  object :customer
  boolean :soft_delete, default: true

  def execute
    if soft_delete
      customer.update_columns(deleted_at: Time.current, customer_phone_number: nil, customer_email: nil, phone_numbers_details: [], emails_details: [])
      customer.social_customer&.update_columns(customer_id: nil)
      User.reset_counters(customer.user_id, :customers)
    else
      customer.social_customer&.update_columns(customer_id: nil)
      customer.destroy
    end
  end
end

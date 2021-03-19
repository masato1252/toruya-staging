# frozen_string_literal: true

class Customers::Delete < ActiveInteraction::Base
  object :customer
  boolean :soft_delete, default: true

  def execute
    # Google contact delete response 200 and 404 return true
    if customer.user.google_user.delete_contact(customer.google_contact_id)
      if soft_delete
        customer.update_columns(deleted_at: Time.current, google_contact_id: nil)
      else
        customer.destroy
      end
    else
      errors.add(:customer, :delete_google_contact_failed)
    end
  end
end

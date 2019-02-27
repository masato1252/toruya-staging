class Customers::Delete < ActiveInteraction::Base
  object :customer

  def execute
    # Google contact delete response 200 and 404 return true
    if customer.user.google_user.delete_contact(customer.google_contact_id)
      customer.update(deleted_at: Time.current)
    else
      errors.add(:customer, :delete_google_contact_failed)
    end
  end
end

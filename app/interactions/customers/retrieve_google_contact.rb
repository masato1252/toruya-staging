class Customers::RetrieveGoogleContact < ActiveInteraction::Base
  object :customer, class: Customer

  def execute
    customer.user.google_user.contact(customer.google_contact_id)
  rescue => e
    Rollbar.error(e, customer_id: customer.id)
    customer.google_down = true
    customer
  end
end

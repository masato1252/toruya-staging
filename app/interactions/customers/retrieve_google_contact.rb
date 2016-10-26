class Customers::RetrieveGoogleContact < ActiveInteraction::Base
  object :customer, class: Customer

  def execute
    user = customer.user
    google_user = GoogleContactsApi::User.new(user.access_token, user.refresh_token)
    google_user.contact(customer.google_contact_id)
  end
end

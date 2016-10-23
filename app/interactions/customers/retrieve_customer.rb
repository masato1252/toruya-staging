class Customers::RetrieveCustomer < ActiveInteraction::Base
  object :user, class: User
  string :google_contact_id

  def execute
  end
end

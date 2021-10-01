# frozen_string_literal: true

class Customers::UpdateAddress < ActiveInteraction::Base
  object :customer
  hash :address_details do
    string :zip_code
    string :region
    string :city
    string :street1, default: nil
    string :street2, default: nil
  end

  def execute
    customer.update(address_details: address_details)
    customer
  end
end

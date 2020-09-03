require "line_client"

module Customers
  class VerifyIdentificationCode < ActiveInteraction::Base
    object :social_customer
    string :uuid
    string :code, default: nil

    def execute
      identification_code = compose(IdentificationCodes::Verify, uuid: uuid, code: code)
      if identification_code && (customer = Customer.find_by(id: identification_code.customer_id))
        compose(SocialCustomers::ConnectWithCustomer, social_customer: social_customer, customer: customer)
      end

      identification_code
    end
  end
end

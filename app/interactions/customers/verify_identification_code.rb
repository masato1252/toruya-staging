require "line_client"

module Customers
  class VerifyIdentificationCode < ActiveInteraction::Base
    object :social_customer
    string :uuid
    string :code, default: nil

    def execute
      identification_code = compose(IdentificationCodes::Verify, uuid: uuid, code: code)
      compose(SocialCustomers::ConnectWithCustomer, social_customer: social_customer, booking_code: identification_code)

      identification_code
    end
  end
end

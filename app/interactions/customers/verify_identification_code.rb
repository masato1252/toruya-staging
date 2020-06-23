module Customers
  class VerifyIdentificationCode < ActiveInteraction::Base
    object :social_customer
    string :uuid
    string :code, default: nil

    def execute
      identification_code = compose(IdentificationCodes::Verify, uuid: uuid, code: code)
      if identification_code
        social_customer.update!(customer_id: identification_code.customer_id)
      end

      identification_code
    end
  end
end

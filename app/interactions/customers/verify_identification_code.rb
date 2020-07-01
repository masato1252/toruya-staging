require "line_client"

module Customers
  class VerifyIdentificationCode < ActiveInteraction::Base
    object :social_customer
    string :uuid
    string :code, default: nil

    def execute
      identification_code = compose(IdentificationCodes::Verify, uuid: uuid, code: code)
      if identification_code
        social_customer.update!(customer_id: identification_code.customer_id)

        LineClient.send(social_customer, I18n.t("line.bot.connected_successfuly"))
        Lines::FeaturesButton.run(social_customer: social_customer)
      end

      identification_code
    end
  end
end

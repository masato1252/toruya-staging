require "line_client"

module SocialCustomers
  class ConnectWithCustomer < ActiveInteraction::Base
    object :social_customer
    object :booking_code, default: nil

    def execute
      if booking_code && booking_code.customer_id
        social_customer.update!(customer_id: booking_code.customer_id)

        LineClient.send(social_customer, I18n.t("line.bot.connected_successfuly"))
        Lines::Features.run(social_customer: social_customer)
      end
    end
  end
end

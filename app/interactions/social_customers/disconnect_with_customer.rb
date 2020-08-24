require "line_client"

module SocialCustomers
  class DisconnectWithCustomer < ActiveInteraction::Base
    object :social_customer

    def execute
      social_customer.update!(customer_id: nil)
      LineClient.unlink_rich_menu(social_customer: social_customer)
    end
  end
end

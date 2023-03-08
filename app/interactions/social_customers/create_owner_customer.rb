# frozen_string_literal: true

require "line_client"

module SocialCustomers
  class CreateOwnerCustomer < ActiveInteraction::Base
    object :social_customer

    def execute
      if social_customer.customer.blank?
        user = social_customer.user

        outcome = Customers::Create.run(
          user: user,
          customer_last_name: user.profile.last_name,
          customer_first_name: user.profile.first_name,
          customer_phonetic_last_name: user.profile.phonetic_last_name,
          customer_phonetic_first_name: user.profile.phonetic_first_name,
          customer_phone_number: user.profile.phone_number
        )

        if outcome.valid?
          SocialCustomers::ConnectWithCustomer.run(
            social_customer: social_customer,
            customer: outcome.result
          )
        end
      end
    end
  end
end

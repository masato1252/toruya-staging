# frozen_string_literal: true

require "line_client"

module SocialCustomers
  class FindOrCreateCustomer < ActiveInteraction::Base
    object :social_customer
    string :customer_last_name
    string :customer_first_name
    string :customer_phonetic_last_name
    string :customer_phonetic_first_name
    string :customer_phone_number

    def execute
      if social_customer.customer.blank?
        user = social_customer.user

        unless customer = Customers::Find.run!(
            user: user,
            last_name: customer_last_name,
            first_name: customer_first_name,
            phone_number: customer_phone_number
        )[:found_customer]
          customer = Customers::Create.run!(
            user: user,
            customer_last_name: customer_last_name,
            customer_first_name: customer_first_name,
            customer_phonetic_last_name: customer_phonetic_last_name,
            customer_phonetic_first_name: customer_phonetic_first_name,
            customer_phone_number: customer_phone_number
          )
        end

        SocialCustomers::ConnectWithCustomer.run(
          social_customer: social_customer,
          customer: customer
        )
      end
    end
  end
end

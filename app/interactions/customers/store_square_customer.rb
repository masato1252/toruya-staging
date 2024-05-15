# frozen_string_literal: true

module Customers
  class StoreSquareCustomer < ActiveInteraction::Base
    object :customer
    string :authorize_token

    def execute
      square_customer_id = customer.square_customer_id

      if square_customer_id
        # update customer a new card
        #  https://developer.squareup.com/forums/t/how-can-we-check-if-the-same-customer-card-exists-before-saving-it-on-file/8402/4
        return square_customer_id
      end

      begin
        square_customer_rsp = client.customers.create_customer(
          body: {
            idempotency_key: SecureRandom.uuid,
            nickname: customer.name,
            given_name: customer.first_name,
            family_name: customer.last_name,
            reference_id: "customer-id-#{customer.id}"
          }
        )

        square_customer_id = square_customer_rsp.data.dig(:customer, :id)

        # Seem no necessary to save card
        # client.cards.create_card(
        #   body: {
        #     idempotency_key: SecureRandom.uuid,
        #     source_id: authorize_token,
        #     card: {
        #       customer_id: square_customer_id,
        #       reference_id: "customer-id-#{customer.id}"
        #     }
        #   }
        # )
        customer.square_customer_id = square_customer_id
        customer.save
        square_customer_id
      rescue => e
        Rollbar.error(e)
        errors.add(:authorize_token, :something_wrong)
      end
    end

    private

    def user
      @user ||= customer.user
    end

    def client
      @client ||= user.square_client
    end
  end
end

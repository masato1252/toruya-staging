# frozen_string_literal: true

require "line_client"
require "message_encryptor"

module SocialCustomers
  class FromOmniauth < ActiveInteraction::Base
    object :auth, class: OmniAuth::AuthHash
    hash :param, strip: false
    string :who, default: nil

    def execute
      social_account = SocialAccount.find(MessageEncryptor.decrypt(param["oauth_social_account_id"]))

      social_customer =
        SocialCustomer
        .create_with(social_rich_menu_key: SocialAccounts::RichMenus::CustomerReservations::KEY)
        .find_or_create_by(
          user_id: social_account.user_id,
          social_user_id: auth.uid,
          social_account_id: social_account.id
      )
      social_customer.update(
        social_user_name: auth.info.name,
        social_user_picture_url: auth.info.image,
        is_owner: customer_is_owner?
      )

      # TODO: test this
      if customer_is_owner? && social_customer.customer.blank?
        user = social_customer.user
        outcome = Customers::Create.run(
          user: social_customer.user,
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

      if param["customer_id"]
        SocialCustomers::ConnectWithCustomer.run(
          social_customer: social_customer,
          customer: Customer.find(param["customer_id"])
        )
      end

      social_customer
    end

    private

    def customer_is_owner?
      who == CallbacksController::SHOP_OWNER_CUSTOMER_SELF
    end
  end
end

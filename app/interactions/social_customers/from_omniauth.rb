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

      social_customer = nil
      with_retry do
        social_customer =
          SocialCustomer
          .create_with(social_rich_menu_key: SocialAccounts::RichMenus::CustomerReservations::KEY)
          .find_or_create_by(
            user_id: social_account.user_id,
            social_user_id: auth.uid,
            social_account_id: social_account.id
          )
      end
      social_customer.social_user_name = auth.info.name
      social_customer.social_user_picture_url = auth.info.image

      unless social_customer.is_owner
        social_customer.is_owner = customer_is_owner?
      end
      social_customer.save

      if customer_is_owner?
        SocialCustomers::CreateOwnerCustomer.run(social_customer: social_customer)
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

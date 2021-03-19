# frozen_string_literal: true

require "line_client"

module SocialCustomers
  class FromOmniauth < ActiveInteraction::Base
    object :auth, class: OmniAuth::AuthHash
    hash :param, strip: false

    def execute
      social_account = SocialAccount.find(param["oauth_social_account_id"])

      social_customer =
        SocialCustomer
        .create_with(social_rich_menu_key: SocialAccounts::RichMenus::CustomerReservations::KEY)
        .find_or_create_by(
          user_id: social_account.user_id,
          social_user_id: auth.uid,
          social_account_id: social_account.id
      )
      social_customer.update(social_user_name: auth.info.name, social_user_picture_url: auth.info.image)

      if param["customer_id"]
        SocialCustomers::ConnectWithCustomer.run(
          social_customer: social_customer,
          customer: Customer.find(param["customer_id"])
        )
      end

      social_customer
    end
  end
end

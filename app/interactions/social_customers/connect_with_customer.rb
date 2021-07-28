# frozen_string_literal: true

require "line_client"

module SocialCustomers
  class ConnectWithCustomer < ActiveInteraction::Base
    object :social_customer
    object :customer

    validate :validate_customer_connection

    def execute
      social_customer.update!(customer_id: customer.id)

      LineClient.send(social_customer, I18n.t("line.bot.connected_successfuly"))

      # XXX: Don't need to link to Toruya's rich menu if it is a official rich menu now.
      if rich_menu = social_customer.social_account.social_rich_menus.find_by(social_name: SocialAccounts::RichMenus::CustomerReservations::KEY)
        RichMenus::Connect.run(social_target: social_customer, social_rich_menu: rich_menu)
      end
    end

    private

    def validate_customer_connection
      if SocialCustomer.where.not(id: social_customer).where(user_id: social_customer.user_id, customer_id: customer.id).exists?
        Rollbar.warning(
          "Customer already connected with customer",
          new_social_customer_id: social_customer.id,
          customer_id: customer.id
        )

        errors.add(:customer, :was_connected_with_other_social_customer)
      end
    end
  end
end

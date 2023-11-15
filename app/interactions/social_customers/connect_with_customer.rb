# frozen_string_literal: true

require "line_client"

module SocialCustomers
  class ConnectWithCustomer < ActiveInteraction::Base
    object :social_customer
    object :customer

    def execute
      other_social_customers = SocialCustomer.where.not(id: social_customer.id).where(user_id: social_customer.user_id, customer_id: customer.id)

      if other_social_customers.exists?
        other_social_customers.update_all(customer_id: nil)
      end

      social_customer.update!(customer_id: customer.id)

      LineClient.send(social_customer, I18n.t("line.bot.connected_successfully"))
      RichMenus::Connect.run(social_target: social_customer, social_rich_menu: social_account.current_rich_menu) if social_account.current_rich_menu
    end

    private

    def social_account
      @social_account ||= social_customer.social_account
    end
  end
end

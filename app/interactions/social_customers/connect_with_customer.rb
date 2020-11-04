require "line_client"

module SocialCustomers
  class ConnectWithCustomer < ActiveInteraction::Base
    object :social_customer
    object :customer

    def execute
      social_customer.update!(customer_id: customer.id)

      LineClient.send(social_customer, I18n.t("line.bot.connected_successfuly"))
      compose(Lines::Features, social_customer: social_customer)
      RichMenus::Connect.run(
        social_target: social_customer,
        social_rich_menu: social_customer.social_account.social_rich_menus.find_by!(social_name: SocialAccounts::RichMenus::CustomerReservations::KEY)
      )
    end
  end
end

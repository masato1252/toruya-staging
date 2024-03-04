module SocialMessages
  class HandleUnread < ActiveInteraction::Base
    object :social_customer
    object :social_message

    def execute
      # TODO: Need to deal with other pending
      if social_message.unread? && social_message.customer? && social_customer.customer
        ::RichMenus::BusinessSwitchRichMenu.run(owner: social_customer.user, rich_menu_key: UserBotLines::RichMenus::DashboardWithNotifications::KEY)
        compose(Users::UpdateCustomerLatestActivityAt, user: social_customer.user)
      end
    end
  end
end

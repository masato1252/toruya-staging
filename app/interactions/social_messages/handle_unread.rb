module SocialMessages
  class HandleUnread < ActiveInteraction::Base
    object :social_customer
    object :social_message

    def execute
      if social_message.unread? && social_message.customer? && social_customer.customer
        UserBotLines::Actions::SwitchRichMenu.run(
          social_user: social_customer.user.social_user,
          rich_menu_key: UserBotLines::RichMenus::DashboardWithNotifications::KEY
        )

        compose(Users::UpdateCustomerLatestActivityAt, user: social_customer.user)
      end
    end
  end
end

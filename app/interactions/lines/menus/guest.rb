module Lines
  module Menus
    class Guest < Base
      IDENTIFY_SHOP_CUSTOMER = "identify_shop_customer".freeze

      private

      def context
        {
          title: I18n.t("line.bot.features.connect_customer.title"),
          desc: I18n.t("line.bot.features.connect_customer.desc"),
          action_templates: actions.map(&:template)
        }
      end

      def chatroom_owner_message_content
        I18n.t("line.bot.features.connect_customer.title")
      end

      def actions
        [
          LineActions::Uri.new(
            action: IDENTIFY_SHOP_CUSTOMER,
            url: Rails.application.routes.url_helpers.lines_identify_shop_customer_url(social_user_id: social_customer.social_user_id)
          )
        ]
      end
    end
  end
end

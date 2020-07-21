require "line_client"

module Lines
  module Menus
    class AllFeatures < Base
      ACTIONS = [
        LineMessages::Postback.new(action: Lines::Actions::BookingPages.class_name, enabled: true),
        LineMessages::Postback.new(action: Lines::Actions::ShopPhone.class_name, enabled: false),
        LineMessages::Postback.new(action: Lines::Actions::OneOnOne.class_name, enabled: false),
        LineMessages::Postback.new(action: Lines::Actions::OnlineBooking.class_name, enabled: true),
      ].freeze

      ENABLED_ACTIONS = ACTIONS.select(&:enabled).freeze
      ACTION_TYPES = ENABLED_ACTIONS.map(&:action).freeze

      private

      def context
        {
          title: "Welcome",
          desc: "These are the services we provides",
          action_templates: ENABLED_ACTIONS.map(&:template)
        }
      end

      def chatroom_owner_message_content
        "These are the services we provide: #{ACTION_TYPES.join(", ")}"
      end
    end
  end
end

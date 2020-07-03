module Lines
  module Menus
    class OnlineBookingFeatures < Base
      ACTIONS = [
        LineMessages::Postback.new(action: Lines::Actions::IncomingReservations.class_name, enabled: true),
      ].freeze

      ENABLED_ACTIONS = ACTIONS.select(&:enabled).freeze
      ACTION_TYPES = ENABLED_ACTIONS.map(&:action).freeze

      private

      def context
        {
          title: I18n.t("line.bot.features.online_booking.title"),
          desc: I18n.t("line.bot.features.online_booking.desc"),
          action_templates: ENABLED_ACTIONS.map(&:template)
        }
      end

      def chatroom_owner_message_content
        "These are the services we provide: #{ACTION_TYPES.join(", ")}"
      end
    end
  end
end

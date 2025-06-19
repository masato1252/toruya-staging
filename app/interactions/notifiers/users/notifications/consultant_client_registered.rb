
module Notifiers
  module Users
    module Notifications
      class ConsultantClientRegistered < Base
        deliver_by_priority [:line, :email, :sms]
        object :client, class: User

        def message
          I18n.t(
            "notifier.notifications.consultant_client_registered.message",
            client_name: client.name,
            url: Rails.application.routes.url_helpers.lines_user_bot_settings_url(business_owner_id: client.id)
          )
        end
      end
    end
  end
end

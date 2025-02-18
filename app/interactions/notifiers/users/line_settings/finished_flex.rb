# frozen_string_literal: true

require "message_encryptor"

module Notifiers
  module Users
    module LineSettings
      class FinishedFlex < Base
        deliver_by_priority [:line, :sms, :email]

        def message
          ::LineMessages::FlexTemplateContainer.template(
            altText: I18n.t("notifier.line_api_settings_finished.card_button"),
            contents: ::LineMessages::FlexTemplateContent.button_card(
              action_templates: [
                LineActions::Uri.new(
                  label: I18n.t("notifier.line_api_settings_finished.card_button"),
                  url: Rails.application.routes.url_helpers.lines_verification_url(MessageEncryptor.encrypt(receiver.social_service_user_id)),
                  btn: 'primary'
                ).template
              ]
            )
          ).to_json
        end

        def content_type
          SocialUserMessages::Create::FLEX_TYPE
        end
      end
    end
  end
end

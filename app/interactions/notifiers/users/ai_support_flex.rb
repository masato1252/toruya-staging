# frozen_string_literal: true

require "message_encryptor"

module Notifiers
  module Users
    class AiSupportFlex < Base
      deliver_by :line

      def message
        LineMessages::FlexTemplateContainer.template(
          altText: I18n.t("notifier.ai_support_flex.button"),
          contents: LineMessages::FlexTemplateContent.title_button_card(
            title: I18n.t("notifier.ai_support_flex.title"),
            action_templates: [
              LineActions::Uri.new(
                label: I18n.t("notifier.ai_support_flex.button"),
                url: Rails.application.routes.url_helpers.new_lines_ai_support_url(encrypted_social_service_user_id: MessageEncryptor.encrypt(receiver.social_service_user_id)),
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

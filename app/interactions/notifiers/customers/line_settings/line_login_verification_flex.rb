# frozen_string_literal: true

module Notifiers
  module Customers
    module LineSettings
      class LineLoginVerificationFlex < Base
        def message
          ::LineMessages::FlexTemplateContainer.template(
            altText: I18n.t("line_verification.confirmation_message.title1"),
            contents: ::LineMessages::FlexTemplateContent.two_header_card(
              title1: I18n.t("line_verification.confirmation_message.title1"),
              title2: I18n.t("line_verification.confirmation_message.title2"),
              action_templates: [
                LineActions::Message.new(
                  label: I18n.t("line_verification.confirmation_message.action"),
                  text: receiver.user.social_user.social_service_user_id,
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

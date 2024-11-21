# frozen_string_literal: true

require "translator"

module CustomMessages
  class ReceiverContent < ActiveInteraction::Base
    object :custom_message
    object :receiver, class: ApplicationRecord # user or customer
    object :variable_source, class: ApplicationRecord, default: nil # reservation

    def execute
      case custom_message.content_type
      when CustomMessage::TEXT_TYPE
        Translator.perform(custom_message.content, variables)
      when CustomMessage::FLEX_TYPE
        variables = JSON.parse(custom_message.content)

        case custom_message.flex_template
        when "video_description_card"
          ::LineMessages::FlexTemplateContainer.template(
            altText: variables["title"],
            contents: ::LineMessages::FlexTemplateContent.video_description_card(
              picture_url: variables["picture_url"],
              content_url: variables["content_url"],
              title: variables["title"],
              context: Translator.perform(variables["context"], variables),
              action_templates: [
                LineActions::Uri.new(
                  label: variables["button_text"],
                  url: variables["content_url"],
                  btn: "primary"
                )
              ].map(&:template)
            )
          ).to_json
        end
      end
    end

    private

    def variables
      if variable_source
        variable_source.message_template_variables(receiver)
      else
        receiver.message_template_variables
      end
    end
  end
end

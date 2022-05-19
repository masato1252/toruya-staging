# frozen_string_literal: true

require "translator"

module Notifiers
  module Users
    module CustomMessages
      class Send < Base
        deliver_by :line

        object :custom_message

        validate :receiver_should_be_user

        def message
          case content_type
          when ::CustomMessage::TEXT_TYPE
            Translator.perform(custom_message.content, receiver.message_template_variables)
          when ::CustomMessage::FLEX_TYPE
            variables = JSON.parse(custom_message.content)

            case custom_message.flex_template
            when "video_description_card"
              LineMessages::FlexTemplateContainer.template(
                altText: variables["title"],
                contents: LineMessages::FlexTemplateContent.video_description_card(
                  picture_url: variables["picture_url"],
                  content_url: variables["content_url"],
                  title: variables["title"],
                  context: Translator.perform(variables["context"], receiver.message_template_variables),
                  action_templates: [
                    LineActions::Uri.new(
                      label: variables["title"],
                      url: variables["content_url"],
                      btn: "primary"
                    )
                  ].map(&:template)
                )
              )
            end
          end
        end

        def content_type
          custom_message.content_type
        end

        def deliverable
          custom_message.receiver_ids.exclude?(receiver.id.to_s)
        end

        def execute
          super

          if errors.blank?
            custom_message.with_lock do
              custom_message.update(receiver_ids: custom_message.receiver_ids.push(receiver.id).map(&:to_s).uniq)
            end
          end

          ::CustomMessages::Users::Next.run(
            custom_message: custom_message,
            receiver: receiver
          )
        end
      end
    end
  end
end

require "line_client"

module Lines
  module Menus
    class Base < ActiveInteraction::Base
      object :social_customer

      def execute
        LineClient.flex(
          social_customer,
          LineMessages::FlexTemplateContainer.template(
            altText: context[:desc],
            contents: LineMessages::FlexTemplateContent.content2(
              title1: context[:title],
              title2: context[:desc],
              action_templates: context[:action_templates]
            )
          )
        )

        SocialMessages::Create.run!(
          social_customer: social_customer,
          content: chatroom_owner_message_content,
          readed: true,
          message_type: SocialMessage.message_types[:bot]
        )
      end

      private

      def context
        raise NotImplementedError, "Subclass must implement this method"
      end

      def chatroom_owner_message_content
        raise NotImplementedError, "Subclass must implement this method"
      end
    end
  end
end

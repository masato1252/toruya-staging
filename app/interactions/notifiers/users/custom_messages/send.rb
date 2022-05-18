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
          Translator.perform(custom_message.content, receiver.message_template_variables)
        end

        def deliverable
          custom_message.receiver_ids.exclude?(receiver.id.to_s)
        end

        def execute
          super

          custom_message.with_lock do
            custom_message.update(receiver_ids: custom_message.receiver_ids.push(receiver.id).map(&:to_s).uniq)
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

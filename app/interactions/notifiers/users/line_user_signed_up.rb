# frozen_string_literal: true

module Notifiers
  module Users
    class LineUserSignedUp < Base
      deliver_by :line

      def message
        # I18n.t("user_bot.guest.user_connect.line.successful_message")
        template = CustomMessages::Template.run!(scenario: CustomMessages::Template::USER_SIGN_UP)

        # Translator.perform(template, online_service.message_template_variables(receiver))
      end

      def execute
        # XXX: Send message
        super

        # The right away message doesn't go through CustomMessages::Send
        if custom_message = CustomMessage.scenario_of(sale_page.product, CustomMessages::Template::ONLINE_SERVICE_PURCHASED).right_away.first
          custom_message.with_lock do
            custom_message.update(receiver_ids: custom_message.receiver_ids.push(receiver.id).uniq)
          end
        end

        ::CustomMessages::Next.run(
          product: sale_page.product,
          scenario: CustomMessage::USER_SIGN_UP,
          receiver: receiver
        )
      end
    end
  end
end

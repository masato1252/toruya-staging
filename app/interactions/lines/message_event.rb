require "line_client"
require "message_encryptor"

class Lines::MessageEvent < ActiveInteraction::Base
  hash :event, strip: false, default: nil
  object :social_customer

  def execute
    if event.present?
      case event["message"]["type"]
      when "text"
        case event["message"]["text"].strip
        when I18n.t("line.bot.keywords.booking_pages")
          Lines::Actions::BookingPages.run(social_customer: social_customer)
        when I18n.t("line.bot.keywords.incoming_reservations")
          Lines::Actions::IncomingReservations.run(social_customer: social_customer)
        when I18n.t("line.bot.keywords.contacts")
          user = social_customer.social_account.user

          actions =
            if user.shops.count == 1 || user.shops.pluck(:phone_number).uniq.count == 1
              [
                LineActions::Uri.new(
                  label: I18n.t("action.call"),
                  url: "tel:#{user.shops.first.phone_number}",
                  btn: "secondary"
                )
              ]
            else
              user.shops.map do |shop|
                LineActions::Uri.new(
                  label: "#{shop.short_name}#{I18n.t("action.call")}",
                  url: "tel:#{shop.phone_number}",
                  btn: "secondary"
                )
              end
            end

          actions.unshift(
            LineActions::Uri.new(
              label: I18n.t("action.send_message"),
              url: Rails.application.routes.url_helpers.lines_contacts_url(encrypted_social_service_user_id: MessageEncryptor.encrypt(social_customer.social_user_id)),
              btn: "secondary"
            )
          )

          LineClient.flex(
            social_customer,
            LineMessages::FlexTemplateContainer.template(
              altText: I18n.t("line.bot.messages.contact.contact_us"),
              contents: LineMessages::FlexTemplateContent.content5(
                title1: I18n.t("line.bot.messages.contact.contact_us"),
                title2: I18n.t("line.bot.messages.contact.contact_us_with_text_or_phone"),
                action_templates: actions.map(&:template)
              )
            )
          )
        end

        compose(
          SocialMessages::Create,
          social_customer: social_customer,
          content: event["message"]["text"],
          readed: true,
          message_type: SocialMessage.message_types[:customer_reply_bot]
        )
      else
        Rollbar.warning("Line chat room don't support message type", event: event)

        LineClient.send(social_customer, "Sorry, we don't support this type of message yet, only support text for now.".freeze)
      end
    end
  end
end

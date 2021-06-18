# frozen_string_literal: true

require "line_client"
require "message_encryptor"

class Lines::MessageEvent < ActiveInteraction::Base
  hash :event, strip: false, default: nil
  object :social_customer

  def execute
    is_keyword = false

    if event.present?
      case event["message"]["type"]
      when "image"
        compose(
          SocialMessages::Create,
          social_customer: social_customer,
          content: {
            originalContentUrl: event["message"]["originalContentUrl"],
            previewImageUrl: event["message"]["previewImageUrl"]
          }.to_json,
          readed: false,
          message_type: SocialMessage.message_types[:customer]
        )
      when "text"
        case event["message"]["text"].strip
        when I18n.t("line.bot.keywords.booking_pages")
          is_keyword = true

          Lines::Actions::BookingPages.run(social_customer: social_customer)
        when I18n.t("line.bot.keywords.incoming_reservations")
          is_keyword = true

          if social_customer.customer
            Lines::Actions::IncomingReservations.run(social_customer: social_customer)
          else
            compose(Lines::Menus::Guest, social_customer: social_customer)
          end
        when "services"
          is_keyword = true

          if social_customer.customer
            Lines::Actions::ActiveOnlineServices.run(social_customer: social_customer)
          else
            compose(Lines::Menus::Guest, social_customer: social_customer)
          end
        when I18n.t("line.bot.keywords.contacts")
          is_keyword = true

          Lines::Actions::Contact.run(social_customer: social_customer)
        else
          if !social_customer.customer
            compose(
              SocialMessages::Create,
              social_customer: social_customer,
              content: I18n.t("line.bot.please_use_contact_feature"),
              readed: true,
              message_type: SocialMessage.message_types[:bot]
            )
            Lines::Actions::Contact.run(social_customer: social_customer)
          end
        end

        is_toruya_customer_message = social_customer.customer && !is_keyword

        compose(
          SocialMessages::Create,
          social_customer: social_customer,
          content: event["message"]["text"],
          readed: !is_toruya_customer_message,
          message_type: is_toruya_customer_message ? SocialMessage.message_types[:customer] : SocialMessage.message_types[:customer_reply_bot]
        )

        if is_toruya_customer_message
          LineClient.send(social_customer, I18n.t("contact_page.message_sent.line_content"))
        end
      else
        Rollbar.warning("Line chat room don't support message type", event: event)

        compose(
          SocialMessages::Create,
          social_customer: social_customer,
          content: I18n.t("line.bot.please_use_contact_feature"),
          readed: true,
          message_type: SocialMessage.message_types[:bot]
        )
        Lines::Actions::Contact.run(social_customer: social_customer)
      end
    end
  end
end

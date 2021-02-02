# frozen_string_literal: true

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
          Lines::Actions::Contact.run(social_customer: social_customer)
        else
          compose(
            SocialMessages::Create,
            social_customer: social_customer,
            content: I18n.t("line.bot.please_use_contact_feature"),
            readed: true,
            message_type: SocialMessage.message_types[:bot]
          )
          Lines::Actions::Contact.run(social_customer: social_customer)
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

require "line_client"

class Lines::MessageEvent < ActiveInteraction::Base
  hash :event, strip: false, default: nil
  object :social_customer

  def execute
    if event.present?
      case event["message"]["type"]
      when "text"
        compose(
          SocialMessages::Create,
          social_customer: social_customer,
          content: event["message"]["text"],
          readed: false,
          message_type: SocialMessage.message_types[:customer]
        )

        case event["message"]["text"].strip
        when I18n.t("line.bot.keywords.booking_pages")
          Lines::Actions::BookingPages.run(social_customer: social_customer)
        when I18n.t("line.bot.keywords.incoming_reservations")
          Lines::Actions::IncomingReservations.run(social_customer: social_customer)
        else
          if social_customer.bot?
            compose(Lines::Features, social_customer: social_customer)
          end
        end
      else
        Rollbar.warning("Line chat room don't support message type", event: event)

        if social_customer.one_on_one?
          LineClient.send(social_customer, "Sorry, we don't support this type of message yet, only support text for now.".freeze)
        end
      end
    end
  end
end

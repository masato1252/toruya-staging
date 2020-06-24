require "line_client"

class Lines::Actions::IncomingReservations < ActiveInteraction::Base
  object :social_customer

  def execute
    reservations = customer.reservations.includes(:shop).where("start_time > ?", Time.current).order("start_time").limit(LineClient::COLUMNS_NUMBER_LIMIT)

    contents = reservations.map do |reservation|
      shop = reservation.shop

      LineMessages::FlexTemplateContent.content1(
        title1: "#{I18n.l(reservation.start_time, format: :short_date_with_wday)} ~ #{I18n.l(reservation.end_time, format: :time_only)}",
        title2: reservation.menus.map(&:display_name).join(", "),
        body: I18n.t("line.bot.messages.incoming_reservations.desc", shop_phone_number: shop.phone_number),
        action_templates: [LineMessages::Uri.new(action: "call", url: "tel:#{shop.phone_number}").template]
      )
    end

    if contents.blank?
      LineClient.send(social_customer, "You don't have any incoming reservations".freeze)
    else
      LineClient.flex(
        social_customer,
        LineMessages::FlexTemplateContainer.carousel_template(
          altText: "There are your incoming reservations",
          contents: contents
        )
      )
    end
  end

  private

  def customer
    @customer ||= social_customer.customer
  end
end

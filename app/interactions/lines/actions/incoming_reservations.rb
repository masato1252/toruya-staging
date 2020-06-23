require "line_client"

class Lines::Actions::IncomingReservations < ActiveInteraction::Base
  object :social_customer

  def execute
    reservations = customer.reservations.includes(:shop).where("start_time > ?", Time.current).order("start_time").limit(LineClient::LINE_COLUMNS_NUMBER_LIMIT)

    columns = reservations.map do |reservation|
      shop = reservation.shop

      message = I18n.t(
        "customer.notifications.sms.reminder",
        customer_name: customer.name,
        shop_name: shop.display_name,
        shop_phone_number: shop.phone_number,
        booking_time: "#{I18n.l(reservation.start_time, format: :long_date_with_wday)} ~ #{I18n.l(reservation.end_time, format: :time_only)}"
      )

      LineMessages::CarouselColumn.template(
        title: I18n.t("customer_mailer.reservation_reminder.title", shop_name: shop.display_name),
        text: message,
        actions: [
          LineMessages::Uri.new(
            action: "call",
            url: "tel:#{shop.phone_number}"
          )
        ]
      )
    end

    if columns.blank?
      LineClient.send(social_customer, "You don't have any incoming reservations".freeze)
    else
      LineClient.carousel_template(social_customer: social_customer, text: "There are your incoming reservations".freeze, columns: columns)
    end
  end

  private

  def customer
    @customer ||= social_customer.customer
  end
end

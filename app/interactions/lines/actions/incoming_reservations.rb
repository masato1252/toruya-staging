# frozen_string_literal: true

require "line_client"

class Lines::Actions::IncomingReservations < ActiveInteraction::Base
  PENDING_ASSET_URL = "https://toruya.s3-ap-southeast-1.amazonaws.com/public/reservation_pending.png"
  ACCEPTED_ASSET_URL = "https://toruya.s3-ap-southeast-1.amazonaws.com/public/reservation_reserved.png"

  object :social_customer

  def execute
    unless customer
      compose(Lines::Menus::Guest, social_customer: social_customer)

      return
    end

    reservations = customer.reservations.where(aasm_state: %w(pending reserved)).includes(:shop).where("start_time > ?", Time.current).order("start_time").limit(LineClient::COLUMNS_NUMBER_LIMIT) || []

    contents = reservations.map do |reservation|
      shop = reservation.shop

      LineMessages::FlexTemplateContent.content6(
        asset_url: reservation.pending? ? PENDING_ASSET_URL : ACCEPTED_ASSET_URL,
        title1: "#{I18n.l(reservation.start_time, format: :short_date_with_wday)}~",
        title2: reservation.menus.map(&:display_name).join(", "),
        title3: shop.display_name,
        body: I18n.t("line.bot.messages.incoming_reservations.desc", shop_phone_number: shop.phone_number),
        action_templates: [
          LineActions::Uri.new(
            label: I18n.t("action.send_message"),
            url: Rails.application.routes.url_helpers.lines_contacts_url(encrypted_social_service_user_id: MessageEncryptor.encrypt(social_customer.social_user_id)),
            btn: "secondary"
          ).template,
          LineActions::Uri.new(action: "call", url: "tel:#{shop.phone_number}", btn: "secondary").template
        ]
      )
    end

    if contents.blank?
      compose(
        SocialMessages::Create,
        social_customer: social_customer,
        content: I18n.t("line.bot.messages.incoming_reservations.no_incoming_messages"),
        readed: true,
        message_type: SocialMessage.message_types[:bot]
      )
    else
      compose(
        SocialMessages::Create,
        social_customer: social_customer,
        content: I18n.t("line.actions.label.incoming_reservations"),
        readed: true,
        message_type: SocialMessage.message_types[:bot],
        send_line: false
      )

      LineClient.flex(
        social_customer,
        LineMessages::FlexTemplateContainer.carousel_template(
          altText: I18n.t("line.actions.label.incoming_reservations"),
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

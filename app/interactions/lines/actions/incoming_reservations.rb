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
      reservation_customer = reservation.reservation_customers.find_by(customer: customer)
      shop = reservation.shop
      action_templates = [
        LineActions::Uri.new(
          label: I18n.t("line.actions.label.reservation_info"),
          url: reservation.booking_info_url,
          btn: "secondary",
          key: social_customer.social_rich_menu_key
        ).template,
      ]

      if shop.phone_number.present? && shop.phone_number.to_i.positive?
        action_templates << LineActions::Uri.new(action: "call", url: "tel:#{shop.phone_number}", btn: "secondary").template
      end

      ::LineMessages::FlexTemplateContent.icon_three_header_body_card(
        asset_url: reservation.pending? ? PENDING_ASSET_URL : ACCEPTED_ASSET_URL,
        title1: "#{I18n.l(reservation.start_time, format: :short_date_with_wday)}~",
        title2: reservation.products_sentence,
        title3: shop.display_name,
        body: reservation_customer.allow_customer_cancel? ? I18n.t("line.bot.messages.incoming_reservations.desc_allow_customer_cancel") : I18n.t("line.bot.messages.incoming_reservations.desc"),
        action_templates: action_templates
      )
    end

    if contents.blank?
      if customer.reservations.exists?
        Lines::Actions::CustomerDashboard.run(social_customer: social_customer)
      else
        compose(
          SocialMessages::Create,
          social_customer: social_customer,
          content: I18n.t("line.bot.messages.incoming_reservations.no_incoming_messages"),
          readed: true,
          message_type: SocialMessage.message_types[:bot]
        )
      end
    else
      contents.push(
        LineMessages::FlexTemplateContent.next_card(
          action_template: LineActions::Uri.template(
            label: I18n.t("line.actions.label.incoming_reservations"),
            url: Rails.application.routes.url_helpers.reservations_lines_customers_dashboard_url(
              public_id: user.public_id,
              social_service_user_id: social_customer.social_user_id
            ),
            key: social_customer.social_rich_menu_key
          )
        )
      )

      line_response = LineClient.flex(
        social_customer,
        ::LineMessages::FlexTemplateContainer.carousel_template(
          altText: I18n.t("line.actions.label.incoming_reservations"),
          contents: contents
        )
      )

      if line_response.is_a?(Net::HTTPOK)
        compose(
          SocialMessages::Create,
          social_customer: social_customer,
          content: I18n.t("line.actions.label.incoming_reservations"),
          readed: true,
          message_type: SocialMessage.message_types[:bot],
          send_line: false
        )
      end
    end
  end

  private

  def customer
    @customer ||= social_customer.customer
  end

  def user
    @user ||= social_customer.social_account.user
  end
end

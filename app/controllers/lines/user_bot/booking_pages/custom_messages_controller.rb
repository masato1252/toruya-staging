# frozen_string_literal: true

require "translator"
require "line_client"

class Lines::UserBot::BookingPages::CustomMessagesController < Lines::UserBotDashboardController
  def index
    @booking_page = super_user.booking_pages.find(params[:booking_page_id])
  end

  def edit_scenario
    @booking_page = super_user.booking_pages.find(params[:booking_page_id])
    @template = CustomMessage.template_of(@booking_page, params[:scenario])
  end

  def update_scenario
    booking_page = super_user.booking_pages.find(params[:booking_page_id])
    outcome = CustomMessages::Update.run(service: booking_page, template: params[:template], scenario: params[:scenario])

    return_json_response(outcome, { redirect_to: lines_user_bot_booking_page_custom_messages_path(params[:service_id]) })
  end

  def demo
    booking_page = super_user.booking_pages.find(params[:booking_page_id])

    custom_message_content = Translator.perform(params[:template], {
      customer_name: current_user.name,
      shop_name: booking_page.shop.display_name,
      shop_phone_number: booking_page.shop.phone_number,
      booking_time: "#{I18n.l(Time.current, format: :long_date_with_wday)} ~ #{I18n.l(Time.current.advance(hours: 1), format: :time_only)}"
    })

    ::LineClient.send(current_user.social_user, custom_message_content)
    head :ok
  end
end

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

    message = CustomMessages::Update.run!(service: booking_page, template: params[:template], scenario: params[:scenario])
    message.demo_message_for_owner

    head :ok
  end
end

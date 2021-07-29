# frozen_string_literal: true

class Lines::UserBot::BookingPages::CustomMessagesController < Lines::UserBotDashboardController
  def index
    @booking_page = super_user.booking_pages.find(params[:booking_page_id])
    @booked_message = CustomMessage.scenario_of(@booking_page, CustomMessage::BOOKING_PAGE_BOOKED).right_away.first
    @one_day_reminder_message = CustomMessage.scenario_of(@booking_page, CustomMessage::BOOKING_PAGE_ONE_DAY_REMINDER).right_away.first
  end

  def edit_scenario
    @booking_page = super_user.booking_pages.find(params[:booking_page_id])
    @message = CustomMessage.find_by(service: @booking_page, id: params[:id])
    @template = @message ? @message.content : CustomMessage.template_of(@booking_page, params[:scenario])
  end

  def update_scenario
    booking_page = super_user.booking_pages.find(params[:booking_page_id])
    outcome = CustomMessages::Update.run(service: booking_page, template: params[:template], scenario: params[:scenario])

    return_json_response(outcome, { redirect_to: lines_user_bot_booking_page_custom_messages_path(params[:service_id]) })
  end
end

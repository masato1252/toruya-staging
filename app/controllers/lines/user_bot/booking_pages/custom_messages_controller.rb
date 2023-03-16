# frozen_string_literal: true

class Lines::UserBot::BookingPages::CustomMessagesController < Lines::UserBotDashboardController
  def index
    @booking_page = Current.business_owner.booking_pages.find(params[:booking_page_id])
    @booked_message = CustomMessage.scenario_of(@booking_page, CustomMessages::Customers::Template::BOOKING_PAGE_BOOKED).right_away.first
    @reservation_confirmed_message = CustomMessage.scenario_of(@booking_page, CustomMessages::Customers::Template::RESERVATION_CONFIRMED).right_away.first
    @one_day_reminder_message = CustomMessage.scenario_of(@booking_page, CustomMessages::Customers::Template::BOOKING_PAGE_ONE_DAY_REMINDER).right_away.first
    @sequence_messages = CustomMessage.scenario_of(@booking_page, CustomMessages::Customers::Template::BOOKING_PAGE_CUSTOM_REMINDER).order("before_minutes ASC")
  end

  def edit_scenario
    @booking_page = Current.business_owner.booking_pages.find(params[:booking_page_id])
    @message = CustomMessage.find_by(service: @booking_page, id: params[:id])
    @template = @message ? @message.content : ::CustomMessages::Customers::Template.run!(product: @booking_page, scenario: params[:scenario])
  end
end

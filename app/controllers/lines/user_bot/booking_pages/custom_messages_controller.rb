# frozen_string_literal: true

class Lines::UserBot::BookingPages::CustomMessagesController < Lines::UserBotDashboardController
  before_action :redirect_to_correct_owner

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

  private

  def redirect_to_correct_owner
    return if Current.business_owner.booking_pages.exists?(id: params[:booking_page_id])

    correct_owner = current_social_user&.manage_accounts&.find do |owner|
      owner.booking_pages.exists?(id: params[:booking_page_id])
    end

    if correct_owner
      redirect_to url_for(params.permit!.merge(business_owner_id: correct_owner.id))
    end
  end
end

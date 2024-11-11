# frozen_string_literal: true

class Lines::UserBot::Settings::CustomMessagesController < Lines::UserBotDashboardController
  before_action :load_shop

  def index
    @booked_message = CustomMessage.scenario_of(@shop, CustomMessages::Customers::Template::BOOKING_PAGE_BOOKED).right_away.first
    @reservation_confirmed_message = CustomMessage.scenario_of(@shop, CustomMessages::Customers::Template::RESERVATION_CONFIRMED).right_away.first
    @one_day_reminder_message = CustomMessage.scenario_of(@shop, CustomMessages::Customers::Template::RESERVATION_ONE_DAY_REMINDER).right_away.first
    @sequence_messages = CustomMessage.scenario_of(@shop, CustomMessages::Customers::Template::SHOP_CUSTOM_REMINDER).order(Arel.sql("CASE WHEN before_minutes IS NULL THEN 1 ELSE 0 END, before_minutes DESC, after_days ASC"))
  end

  def edit_scenario
    @message = CustomMessage.find_by(service: @shop, id: params[:id])
    @template = @message ? @message.content : ::CustomMessages::Customers::Template.run!(product: @shop, scenario: params[:scenario])
  end

  private

  def load_shop
    @shop = Current.business_owner.shops.find(params[:shop_id])
  end
end

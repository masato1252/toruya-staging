# frozen_string_literal: true

class Lines::UserBot::ToursController < Lines::UserBotDashboardController
  layout false

  def line_settings_required_for_online_service; end
  def line_settings_required_for_booking_page; end
end

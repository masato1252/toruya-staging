# frozen_string_literal: true

module AdminHelper
  def scenario_label(scenario_key)
    case scenario_key
    when CustomMessages::Users::Template::BOOKING_PAGE_NOT_ENOUGH_PAGE_VIEW
      "[Booking#1] #{scenario_key.titleize}"
    when CustomMessages::Users::Template::BOOKING_PAGE_NOT_ENOUGH_BOOKING
      "[Booking#2] #{scenario_key.titleize}"
    else
      scenario_key.titleize
    end
  end
end

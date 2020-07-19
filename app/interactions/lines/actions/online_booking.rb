require "line_client"

class Lines::Actions::OnlineBooking < ActiveInteraction::Base
  object :social_customer

  def execute
    compose(Lines::Menus::OnlineBookingFeatures, social_customer: social_customer)
  end
end

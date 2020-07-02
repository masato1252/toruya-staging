require "line_client"

class Lines::Features < ActiveInteraction::Base
  object :social_customer

  def execute
    if social_customer.customer
      if Lines::Menus::AllFeatures::ENABLED_ACTIONS.length == 1
        # TODO: Refactor could choose any single one feature
        compose(Lines::Menus::OnlineBookingFeatures, social_customer: social_customer)
      else
        compose(Lines::Menus::AllFeatures, social_customer: social_customer)
      end
    else
      compose(Lines::Menus::Guest, social_customer: social_customer)
    end
  end
end

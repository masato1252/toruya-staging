require "line_client"

class Lines::Actions::OneOnOne < ActiveInteraction::Base
  object :social_customer

  def execute
    social_customer.one_on_one!

    LineClient.send(social_customer, "How could we help you? we would reply you as soon as possible")
  end
end

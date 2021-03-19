# frozen_string_literal: true

require "line_client"

class Lines::Actions::OneOnOne < ActiveInteraction::Base
  object :social_customer

  def execute
    social_customer.one_on_one!
    UserChannel.broadcast_to(social_customer.user, { type: "toggle_customer_conversation_state", data: SocialCustomerSerializer.new(social_customer).attributes_hash })
    LineClient.send(social_customer, "How could we help you? we would reply you as soon as possible")
  end
end

# frozen_string_literal: true

require "line_client"

class Lines::FollowEvent < ActiveInteraction::Base
  hash :event, strip: false
  object :social_customer

  def execute
  end
end

# frozen_string_literal: true

require "slack_client"

class HiJob < ApplicationJob
  queue_as :low_priority

  def perform(object, channel_name)
    if object.hi_message.present?
      SlackClient.send(channel: channel_name || "sayhi", text: object.hi_message)
    end
  end
end

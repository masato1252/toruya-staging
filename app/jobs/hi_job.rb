# frozen_string_literal: true

require "slack_client"

class HiJob < ApplicationJob
  queue_as :low_priority

  def perform(hi_message, channel_name = nil)
    SlackClient.send(channel: channel_name || "sayhi", text: hi_message)
  end
end

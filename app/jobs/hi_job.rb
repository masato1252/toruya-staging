# frozen_string_literal: true

require "slack_client"

class HiJob < ApplicationJob
  queue_as :low_priority

  # Support object was because sometime, we don't want to the status of object right away,
  # for example: after customer paid the bill, otherwise, it usually always be pending status.
  def perform(hiable_object_or_hi_message, channel_name = nil)
    channel = channel_name || "sayhi"
    text = hiable_object_or_hi_message.is_a?(String) ? hiable_object_or_hi_message : hiable_object_or_hi_message.hi_message

    SlackClient.send(channel: channel, text: text)
  end
end

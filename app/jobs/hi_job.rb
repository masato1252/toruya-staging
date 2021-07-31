# frozen_string_literal: true

require "slack_client"
require "mixpanel_tracker"

class HiJob < ApplicationJob
  queue_as :low_priority

  def perform(object, channel_name, track_event)
    if object.hi_message.present?
      SlackClient.send(channel: channel_name || "sayhi", text: object.hi_message)
    end

    if track_event
      ::MixpanelTracker.track object.id, track_event
    end
  end
end

# frozen_string_literal: true

require "mixpanel_tracker"

class HiEventJob < ApplicationJob
  queue_as :low_priority
  before_enqueue { throw(:abort) if ENV["LOW_PRIORITY_ANALYTICS_DISABLED"] == "true" }

  def perform(object, track_event)
    ::MixpanelTracker.track object.id, track_event
  end
end

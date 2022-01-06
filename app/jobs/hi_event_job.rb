# frozen_string_literal: true

require "mixpanel_tracker"

class HiEventJob < ApplicationJob
  queue_as :low_priority

  def perform(object, track_event)
    ::MixpanelTracker.track object.id, track_event
  end
end

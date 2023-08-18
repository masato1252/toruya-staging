# frozen_string_literal: true

require "active_interaction_delayer"
require "retry"

ActiveInteraction::Base.extend(ActiveInteractionDelayer)
ActiveInteraction::Base.include(Retry)

Delayed::Worker.queue_attributes = {
  high_priority: { priority: 1 },
  default: { priority: 10 },
  low_priority: { priority: 20 },
}

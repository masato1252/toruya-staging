# frozen_string_literal: true

require "active_interaction_delayer"
require "retry"

ActiveInteraction::Base.extend(ActiveInteractionDelayer)
ActiveInteraction::Base.include(Retry)

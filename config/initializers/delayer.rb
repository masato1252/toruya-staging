# frozen_string_literal: true

require "active_interaction_delayer"

ActiveInteraction::Base.extend(ActiveInteractionDelayer)

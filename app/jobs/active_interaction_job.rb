# frozen_string_literal: true

class ActiveInteractionJob < ApplicationJob
  debounce # default 20 seconds
  throttle # default 20 seconds

  queue_as :default

  def perform(active_interaction_class, args={})
    bang = args.delete(:bang)

    if bang
      ActiveInteraction::Base.const_get(active_interaction_class).run!(args)
    else
      ActiveInteraction::Base.const_get(active_interaction_class).run(args)
    end
  end
end

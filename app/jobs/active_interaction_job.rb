# frozen_string_literal: true

class ActiveInteractionJob < ApplicationJob
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

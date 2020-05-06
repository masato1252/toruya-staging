class ActiveInteractionJob < ApplicationJob
  queue_as :default

  def perform(active_interaction_class, args={})
    ActiveInteraction::Base.const_get(active_interaction_class).run(args)
  end
end

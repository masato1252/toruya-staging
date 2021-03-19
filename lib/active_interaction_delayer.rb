# frozen_string_literal: true

module ActiveInteractionDelaer
  def perform_later(args={})
    ActiveInteractionJob.perform_later(self.to_s, args)
  end
end

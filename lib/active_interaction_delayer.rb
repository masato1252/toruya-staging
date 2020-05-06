module ActiveInteractionDelaer
  def perform_later(args={})
    ActiveInteractionJob.perform_later(self.to_s, args)
  end
end

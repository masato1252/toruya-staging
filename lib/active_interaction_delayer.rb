# frozen_string_literal: true

module ActiveInteractionDelayer
  def perform_later(args={})
    ActiveInteractionJob.perform_later(self.to_s, args)
  end

  def perform_at(args = {})
    schedule_at = args.delete(:schedule_at)

    ActiveInteractionJob.set(wait_until: schedule_at).perform_later(self.to_s, args)
  end

  def perform_later!(args={})
    args.merge!(bang: true)

    ActiveInteractionJob.perform_later(self.to_s, args)
  end

  def perform_at!(args = {})
    schedule_at = args.delete(:schedule_at)
    args.merge!(bang: true)

    ActiveInteractionJob.set(wait_until: schedule_at).perform_later(self.to_s, args)
  end
end

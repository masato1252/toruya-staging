# frozen_string_literal: true

module SayHi
  extend ActiveSupport::Concern

  included do
    after_commit :say_hi, on: :create
    class_attribute :channel_name, instance_writer: false
    class_attribute :track_event, instance_writer: false
  end

  def say_hi
    if Rails.configuration.x.env.production?
      HiJob.set(wait_until: 5.minutes.from_now).perform_later(hi_message, channel_name) if hi_message.present?
      HiEventJob.perform_later(self, track_event) if track_event.present?
    end
  end

  class_methods do
    def hi_channel_name(channel_name)
      self.channel_name = channel_name
    end

    def hi_track_event(track_event)
      self.track_event = track_event
    end
  end
end

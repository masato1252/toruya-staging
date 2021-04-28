# frozen_string_literal: true

module SayHi
  extend ActiveSupport::Concern

  included do
    after_commit :say_hi, on: :create
    class_attribute :channel_name, instance_writer: false
  end

  def say_hi
    if Rails.configuration.x.env.production?
      HiJob.perform_later(self, channel_name)
    end
  end

  class_methods do
    def hi_channel_name(channel_name)
      self.channel_name = channel_name
    end
  end
end

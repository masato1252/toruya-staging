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
      if self.hi_message.present?

        if channel_name == "toruya_users_support"
          recent_messages_count = SocialUserMessage.where(social_user_id: self.social_user_id).where(created_at: 2.minutes.ago..).count

          redirect_channel_name = self.social_user.locale == "ja" ? "toruya_users_support" : "#{self.social_user.locale}_toruya_users_support"
          HiJob.set(wait: (recent_messages_count * 10).seconds).perform_later(self, redirect_channel_name)
        else
          HiJob.set(wait_until: 5.minutes.from_now).perform_later(self, channel_name)
        end
      end
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

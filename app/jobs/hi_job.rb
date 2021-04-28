# frozen_string_literal: true

class HiJob < ApplicationJob
  queue_as :low_priority

  def perform(object, channel_name)
    if object.hi_message.present?
      Slack::Web::Client.new.chat_postMessage(channel: channel_name || "sayhi", text: object.hi_message)
    end
  end
end

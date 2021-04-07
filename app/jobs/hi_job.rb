# frozen_string_literal: true

class HiJob < ApplicationJob
  queue_as :urgent

  def perform(object)
    Slack::Web::Client.new.chat_postMessage(channel: 'sayhi', text: object.hi_message)
  end
end

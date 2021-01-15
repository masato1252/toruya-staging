module SayHi
  extend ActiveSupport::Concern

  included do
    after_commit :say_hi, on: :create
  end

  def say_hi
    if Rails.configuration.x.env.production?
      Slack::Web::Client.new.chat_postMessage(channel: 'sayhi', text: hi_message)
    end
  end
end

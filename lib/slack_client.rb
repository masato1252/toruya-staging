# frozen_string_literal: true

# https://api.slack.com/messaging/sending
class SlackClient
  include HTTParty
  base_uri 'https://slack.com/api'
  headers Authorization: "Bearer #{ENV['SLACK_API_TOKEN']}"

  def self.send(args)
    Hashie::Mash.new(post("/chat.postMessage", body: args))
  end
end

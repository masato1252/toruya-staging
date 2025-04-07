# frozen_string_literal: true

# https://api.slack.com/messaging/sending
class SlackClient
  include HTTParty
  base_uri 'https://slack.com/api'

  class << self
    def send(args)
      response = post(
        "/chat.postMessage",
        body: args.to_json,
        headers: {
          'Authorization' => "Bearer #{ENV['SLACK_BOT_TOKEN']}",
          'Content-Type' => 'application/json; charset=utf-8'
        }
      )

      result = Hashie::Mash.new(response)

      unless result.ok
        Rails.logger.error("Slack API Error: #{result.error}")
        Rollbar.error("Slack API Error", error: result.error, args: args) if defined?(Rollbar)
      end

      result
    end
  end
end
